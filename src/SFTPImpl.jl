## Load packages
# import FileWatching as fw
import Downloads
import LibCURL
import URIs
import CSV
import Dates
import Downloads: Downloader
import URIs: URI
import Logging

## Define constants
const fileSeparator = Sys.iswindows() ? "\\" : "/"


## Structs

"""
    mutable struct SFTP

`SFTP` manages the connection to the server and stores all relevant connection data.

# Constructors

    SFTP(url::AbstractString, username::AbstractString, public_key_file::AbstractString, public_key_file::AbstractString; kwargs)::SFTP
    SFTP(url::AbstractString, username::AbstractString, password::AbstractString=""; kwargs)::SFTP

Construct an `SFTP` client from the url and either user information or public and private key file.

## Arguments

- `url`: The url to connect to, e.g., sftp://mysite.com
- `username`/`password`: user credentials
- `public_key_file`/`public_key_file`: authentication certificates

## Keyword arguments

- `create_known_hosts_entry`: Automatically create an entry in known hosts
- `disable_verify_peer`: verify the authenticity of the peer's certificate
- `disable_verify_host`: verify the host in the server's TLS certificate
- `verbose`: display a lot of verbose curl information


# Important notice

A username must be provided for both methods to work.

Before using the constructor method for certificate authentication, private and public
key files must be created and stored in the ~/.ssh folder and on the server, e.g.
~/.ssh/id_rsa and ~/.ssh/id_rsa.pub. Additionally, the host must be added to the
known_hosts file in the ~/.ssh folder.

The correct setup can be tested in the terminal with
`ssh myuser@mysitewhereIhaveACertificate.com`.


# Examples

    sftp = SFTP("sftp://mysitewhereIhaveACertificate.com", "myuser", "test.pub", "test.pem")
    sftp = SFTP("sftp://mysitewhereIhaveACertificate.com", "myuser")
    sftp = SFTP("sftp://test.rebex.net", "demo", "password")
"""
mutable struct SFTP
    downloader::Downloader
    uri::URI
    username::String
    password::String
    disable_verify_peer::Bool
    disable_verify_host::Bool
    verbose::Bool
    public_key_file::String
    private_key_file::String
end


struct SFTPStatStruct
    desc::String
    mode    :: UInt
    nlink   :: Int
    uid     :: String
    gid     :: String
    size    :: Int64
    mtime   :: Float64
end


## External constructors

# See SFTP struct for help/docstrings
function SFTP(
    url::AbstractString,
    username::AbstractString,
    public_key_file::AbstractString,
    private_key_file::AbstractString;
    disable_verify_peer::Bool=false,
    disable_verify_host::Bool=false,
    verbose::Bool=false
)::SFTP
    # Setup Downloader
    downloader = Downloader()
    # Set URI, ensure trailing slash in path
    uri = set_url(url)
    # Instantiate and post-process easy hooks
    sftp = SFTP(downloader, uri, username, "", disable_verify_peer, disable_verify_host, verbose, public_key_file, private_key_file)
    reset_easy_hook(sftp)
    return sftp
end


# See SFTP struct for help/docstrings
function SFTP(
    url::AbstractString,
    username::AbstractString,
    password::AbstractString="";
    create_known_hosts_entry::Bool=true,
    disable_verify_peer::Bool=false,
    disable_verify_host::Bool=false,
    verbose::Bool=false
)::SFTP
    # Setup Downloader
    downloader = Downloader()
    # Set URI, ensure trailing slash in path
    uri = set_url(url)
    # Update known_hosts, if selected
    if !isempty(password) && create_known_hosts_entry
        check_and_create_fingerprint(uri.host)
    end
    # Instantiate and post-process easy hooks
    sftp = SFTP(downloader, uri, username, password, disable_verify_peer, disable_verify_host, verbose, "", "")
    reset_easy_hook(sftp)
    return sftp
end


## Helper functions for SFTP struct and fingerprints


Base.show(io::IO, sftp::SFTP) =  println(io, "SFTP($(sftp.username)@$(sftp.uri.host))")


"""
    set_url(url::URI)::URI

Ensure URI path with trailing slash.
"""
function set_url(url::AbstractString)::URI
    uri = URI(url)
    isdirpath(uri.path) || (path = uri.path * '/')
    URIs.resolvereference(uri, URIs.escapepath(uri.path))
end


"""
    check_and_create_fingerprint(hostNameOrIP::AbstractString)::Nothing

Check for `hostNameOrIP` in known_hosts.
"""
function check_and_create_fingerprint(hostNameOrIP::AbstractString)::Nothing
    try
        # Try to read known_hosts file
        known_hosts_file = joinpath(homedir(), ".ssh", "known_hosts")
        rows=CSV.File(known_hosts_file;delim=" ",types=String,header=false)
        # Scan known hosts for current host
        for row in rows
            row[1] != hostNameOrIP && continue
            @info "$hostNameOrIP found host in known_hosts"
            # check the entry we found
            fingerprintAlgo = row[2]
            #These are known to work
            if (fingerprintAlgo == "ecdsa-sha2-nistp256" || fingerprintAlgo == "ecdsa-sha2-nistp256" ||
                fingerprintAlgo ==  "ecdsa-sha2-nistp521"  || fingerprintAlgo == "ssh-rsa" )
                return
            else
                @warn "correct fingerprint not found in known_hosts"
            end
        end
        @info "Creating fingerprint" hostNameOrIP
        create_fingerprint(hostNameOrIP)
    catch error
        @warn "An error occurred during fingerprint check; creating a new fingerprint" error
        create_fingerprint(hostNameOrIP)
    end
end


"""
    create_fingerprint(hostNameOrIP::AbstractString)::Nothing

Create a new entry in known_hosts for `hostNameOrIP`.
"""
function create_fingerprint(hostNameOrIP::AbstractString)::Nothing
    # Check for .ssh/known_hosts and create if missing
    sshdir = mkpath(joinpath(homedir(), ".ssh"))
    known_hosts = joinpath(sshdir, "known_hosts")
    # Import ssh key as trusted key or throw error (except for known test issue)
    keyscan = ""
    try
        keyscan = readchomp(`ssh-keyscan -t ssh-rsa $(hostNameOrIP)`)
    catch
        @error "keyscan failed; check if ssh-keyscan is installed"
        if hostNameOrIP == "test.rebex.net"
            # Fix missing keyscan on NanoSoldier
            keyscan = """test.rebex.net ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAkRM6RxDdi3uAGogR3nsQMpmt43X4WnwgMzs8VkwUCqikewxqk4U7EyUSOUeT3CoUNOtywrkNbH83e6/yQgzc3M8i/eDzYtXaNGcKyLfy3Ci6XOwiLLOx1z2AGvvTXln1RXtve+Tn1RTr1BhXVh2cUYbiuVtTWqbEgErT20n4GWD4wv7FhkDbLXNi8DX07F9v7+jH67i0kyGm+E3rE+SaCMRo3zXE6VO+ijcm9HdVxfltQwOYLfuPXM2t5aUSfa96KJcA0I4RCMzA/8Dl9hXGfbWdbD2hK1ZQ1pLvvpNPPyKKjPZcMpOznprbg+jIlsZMWIHt7mq2OJXSdruhRrGzZw=="""
        else
            rethrow()
        end
    end

    # Add host to known hosts
    @info "Adding fingerprint to known_hosts" keyscan
    open(known_hosts, "a+") do f
        println(f, keyscan)
    end
end


function setStandardOptions(sftp, easy, info)
    if !isempty(sftp.username)
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_USERNAME, sftp.username)
    end
    if !isempty(sftp.password)
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_PASSWORD, sftp.password)
    end
    if sftp.disable_verify_host
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_SSL_VERIFYHOST , 0)
    end
    if sftp.disable_verify_peer
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_SSL_VERIFYPEER , 1)
    end
    if !isempty(sftp.public_key_file)
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_SSH_PUBLIC_KEYFILE, sftp.public_key_file)
    end
    if !isempty(sftp.private_key_file)
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_SSH_PRIVATE_KEYFILE, sftp.private_key_file)
    end
    if sftp.verbose
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_VERBOSE, 1)
    end
end


function reset_easy_hook(sftp::SFTP)
    downloader = sftp.downloader
    downloader.easy_hook = (easy, info) -> begin
        setStandardOptions(sftp, easy, info)
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_DIRLISTONLY, 1)
    end
end


function sftpescapepath(path::String)
    return URIs.escapepath(path)
end


#=
    Note, this function should not use URL:s since CURL:s api need spaces
=#
function handleRelativePath(fileName, sftp::SFTP)
    baseUrl = string(sftp.uri)
    @debug "base url" baseUrl
    resolvedReference = URIs.resolvereference(baseUrl, fileName)
    fileName = "'" * URIs.unescapeuri(resolvedReference.path) * "'"
    @debug "file name" fileName
    return fileName
end


function ftp_command(sftp::SFTP, command::String)
    slist = Ptr{Cvoid}(0)
    slist = LibCURL.curl_slist_append(slist, command)
    sftp.downloader.easy_hook = (easy, info) -> begin
        setStandardOptions(sftp, easy, info)
        Downloads.Curl.setopt(easy,  Downloads.Curl.CURLOPT_QUOTE, slist)
    end

    uri = string(sftp.uri)
    io = IOBuffer()
    output = nothing

    try
        output = Downloads.download(uri, io; sftp.downloader)
    finally
        LibCURL.curl_slist_free_all(slist)
        reset_easy_hook(sftp)
    end

    return output
end


function sftpstat2(sftp, dir::String)
    stats = sftpstat(sftp, dir)
    a = filter(x->x.desc != "." && x.desc != "..",stats )
    return a;
end


function myjoinpath(path::AbstractString, name::AbstractString)
    path == "." && return name
    path*"/" * name * "/"
end


"""
    SFTPClient.walkdir(sftp::SFTP, root; topdown=true, follow_symlinks=false, onerror=throw)

    Return an iterator that walks the directory tree of a directory.
The iterator returns a tuple containing `(rootpath, dirs, files)`.


# Examples
```julia
for (root, dirs, files) in walkdir(sftp, ".")
    println("Directories in \$root")
    for dir in dirs
        println(joinpath(root, dir)) # path to directories
    end
    println("Files in \$root")
    for file in files
        println(joinpath(root, file)) # path to files
    end
end
```
"""
function Base.walkdir(sftp::SFTP, root; topdown=true, follow_symlinks=false, onerror=throw)
    function _walkdir(chnl, root)
        tryf2( f, sftp, p) = try
            f(sftp, p)
        catch err
            show(err)
            isa(err, Base.IOError) || rethrow()
            try
                onerror(err)
            catch err2
                close(chnl, err2)
            end
            return
        end

        tryf( f, p) = try
            f(p)
        catch err
            show(err)
            isa(err, Base.IOError) || rethrow()
            try
                onerror(err)
            catch err2
                close(chnl, err2)
            end
            return
        end

        content = tryf2(sftpstat2, sftp , root)
        content === nothing && return
        dirs = Vector{String}()
        files = Vector{String}()
        for statstruct in content
            name = statstruct.desc
            path = myjoinpath(root, name)
            isadir = tryf(isdir, statstruct)
            # If we're not following symlinks, then treat all symlinks as files
            if (!follow_symlinks && something(tryf(islink, statstruct), true)) || !something(tryf(isdir, statstruct), false)
                push!(files, name)
            else
                push!(dirs, name)
            end
        end

        if topdown
            push!(chnl, (root, dirs, files))
        end
        for dir in dirs
            _walkdir(chnl, myjoinpath(root, dir))
        end
        if !topdown
            push!(chnl, (root, dirs, files))
        end
        nothing
    end
    return Channel{Tuple{String,Vector{String},Vector{String}}}(chnl -> _walkdir(chnl, root))
end


Base.broadcastable(sftp::SFTP) = Ref(sftp)


"""
    islink(path) -> Bool

Return `true` if `path` is a symbolic link, `false` otherwise.
"""
Base.islink(st::SFTPStatStruct) = filemode(st) & 0xf000 == 0xa000


"""
    Base.isdir(st::SFTPStatStruct)

Test if st is a directory
"""
Base.isdir(st::SFTPStatStruct) = filemode(st) & 0xf000 == 0x4000


"""
    Base.isfile(st::SFTPStatStruct)

Test if st is a file
"""
Base.isfile(st::SFTPStatStruct) = filemode(st) & 0xf000 == 0x8000


"""
    Base.isdir(st::SFTPStatStruct)

Get the filemode of the directory
"""
Base.filemode(st::SFTPStatStruct) = st.mode


function parseDate(monthPart::String, dayPart::String, yearOrTimePart::String)
     yearStr::String = occursin(":", yearOrTimePart) ? string(Dates.year(Dates.now())) : yearOrTimePart
     timeStr::String = !occursin(":", yearOrTimePart) ? "00:00" : yearOrTimePart

     dateTime = Dates.DateTime("$monthPart $dayPart $yearStr $timeStr", Dates.dateformat"u d yyyy H:M ")

    return Dates.datetime2unix(dateTime)
end


function parseMode(s::String)::UInt
    length(s) != 10 && error("Not correct length")
    dirChar = s[1]
    dir = (dirChar == 'd') ? 0x4000 : 0x8000

    owner = strToNumber(s[2:4])
    group = strToNumber(s[5:7])
    anyone = strToNumber(s[8:10])

    return dir + owner * 8^2 + group * 8^1 + anyone * 8^0
end


function strToNumber(s::String)::Int64
    b1 = (s[1] != '-') ?  4 : 0
    b2 = (s[2] != '-') ?  2 : 0
    b3 = (s[3] != '-') ?  1 : 0
    return b1+b2+b3
end


function parseStat(s::String)
    resultVec = Vector{String}(undef, 9)
    lastIndex = 1
    parseCounter = 1
    stringLength = length(s)

    i = 1
    while (i < stringLength)
        c = s[i]
        if c == ' '
            resultVec[parseCounter] = s[lastIndex:i-1]
            parseCounter += 1
            while (i < stringLength && c == ' ')
                i += 1
                c = s[i]
            end
            lastIndex = i

            if parseCounter == 9
                resultVec[parseCounter] = s[lastIndex:end]
                break
            end
        end
        i += 1
    end
    return resultVec
end


function makeStruct(stats::Vector{String})::SFTPStatStruct
    SFTPStatStruct(stats[9], parseMode(stats[1]),  parse(Int64, stats[2]), stats[3], stats[4], parse(Int64, stats[5]), parseDate(stats[6], stats[7], stats[8]))
end


"""
    sftpstat(sftp::SFTP)

Like Julia stat, but returns a Vector of SFTPStatStructs. Note that you can only run this on directories. Can be used for checking if a file was modified, and much more.
"""
sftpstat(sftp::SFTP) = sftpstat(sftp::SFTP, ".")


"""
    sftpstat(sftp::SFTP, path::AbstractString)

Like Julia stat, but returns a Vector of SFTPStatStructs. Note that you can only run this on directories. Can be used for checking if a file was modified, and much more.
"""
function sftpstat(sftp::SFTP, path::AbstractString)
    sftp.downloader.easy_hook = (easy, info) -> begin
        setStandardOptions(sftp, easy, info)
    end

    output = nothing
    try
        if !isdirpath(path)
            path = path * "/"
        end
        newUrl = URIs.resolvereference(sftp.uri,sftpescapepath(path))
        io = IOBuffer();
        try
            output = Downloads.download(string(newUrl), io; sftp.downloader)
        finally
            reset_easy_hook(sftp)
        end

        # Don't know why this is necessary
        res = String(take!(io))
        io2 = IOBuffer(res)
        stats = readlines(io2;keep=false)

        return makeStruct.(parseStat.(stats))
        #return files
    catch e
        rethrow(e)
    end
end


"""
    upload(sftp::SFTP, file_name::AbstractString)

Upload (put) a file to the server. Broadcasting can be used too.

files=readdir()
upload.(sftp,files)
"""
function upload(sftp::SFTP, file_name::AbstractString)
    open(file_name, "r") do local_file
        file = URIs.escapeuri(basename(file_name))
        uri = URIs.resolvereference(sftp.uri, file)
        output = Downloads.request(string(uri), input=local_file;downloader=sftp.downloader)
    end

    return nothing
end


"""
    SFTPClient.download(sftp::SFTP, file_name::AbstractString,
        output = tempname();downloadDir::Union{String, Nothing}=nothing)

Download a file. You can download it and use it directly, or save it to a file.
Specify downloadDir if you want to save downloaded files. You can also use broadcasting.
Example:

sftp = SFTP("sftp://test.rebex.net/pub/example/", "demo", "password")
files=readdir(sftp)
downloadDir="/tmp"
SFTPClient.download.(sftp, files, downloadDir=downloadDir)

You can also use it like this:
df=DataFrame(CSV.File(SFTPClient.download(sftp, "/mydir/test.csv")))
"""
function Base.download(
    sftp::SFTP,
    file_name::AbstractString,
    output = tempname();
    downloadDir::String = ""
)
    if file_name == "." || file_name == ".."
        return
    end

    if !isempty(downloadDir)
        if !isdirpath(downloadDir)
            downloadDir = downloadDir * fileSeparator
        end
        if downloadDir == "."
            downloadDir = downloadDir * fileSeparator
        end
        output = downloadDir * file_name
     end

     uri = URIs.resolvereference(sftp.uri, URIs.escapeuri(file_name))
    try
        output = Downloads.download(string(uri), output; sftp.downloader)
    catch e
        rethrow(e)
    end
    return output
end


"""
    readdir(sftp::SFTP, join::Bool = false, sort::Bool = true)

Reads the current directory. Returns a vector of Strings just like the regular readdir function.
"""
function Base.readdir(sftp::SFTP, join::Bool = false, sort::Bool = true)
    output = nothing
    try
        uriString = string(sftp.uri)
        if !endswith(uriString, "/")
            uriString = uriString * "/"
            sftp.uri = URI(uriString)
        end

        dir = sftp.uri.path
        io = IOBuffer();
        output = Downloads.download(uriString, io; sftp.downloader)

        # Don't know why this is necessary
        res = String(take!(io))
        io2 = IOBuffer(res)
        files = readlines(io2;keep=false)

        files = filter(x->x != "..", files)
        files = filter(x->x != ".", files)

        sort && sort!(files)
        join && return joinpath.(dir, files)

        return files
    catch
        rethrow()
    end
end


"""
    cd(sftp::SFTP, dir::AbstractString)

Change the directory for the SFTP client.
"""
function Base.cd(sftp::SFTP, dir::AbstractString)
    oldUrl = sftp.uri

    # If we fail, set back to the old url
    try
        if !isdirpath(dir)
            dir = dir * "/"
        end
        newUrl = URIs.resolvereference(oldUrl,sftpescapepath(dir))
        sftp.uri = newUrl
        readdir(sftp)
    catch
        sftp.uri = oldUrl
        rethrow()
    end
    return nothing
end


"""
    rm(sftp::SFTP, file_name::AbstractString)

Remove (delete) the file
"""
function Base.rm(sftp::SFTP, file_name::AbstractString)
    resp = ftp_command(sftp, "rm $(handleRelativePath(file_name, sftp))")
    return nothing
end


"""
    rmdir(sftp::SFTP, dir_name::AbstractString)

Remove (delete) the directory
"""
function rmdir(sftp::SFTP, dir_name::AbstractString)
    resp = ftp_command(sftp, "rmdir $(handleRelativePath(dir_name, sftp))")
    return nothing
end


"""
    mkdir(sftp::SFTP, dir::AbstractString)

Create a directory
"""
function Base.mkdir(sftp::SFTP, dir::AbstractString)
    resp = ftp_command(sftp, "mkdir $(handleRelativePath(dir, sftp))")
    return nothing
end


"""
    mv(
        sftp::SFTP,
        old_name::AbstractString,
        new_name::AbstractString;
    )

Move, i.e., rename the file.
"""
function Base.mv(
    sftp::SFTP,
    old_name::AbstractString,
    new_name::AbstractString;
)
    resp = ftp_command(sftp, "rename $(handleRelativePath(old_name, sftp)) $(handleRelativePath(new_name, sftp))")
    return nothing
end
