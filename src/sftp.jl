## Load packages
# import FileWatching as fw
import Downloads
import LibCURL
import URIs
import CSV
import Dates
import Downloads: Downloader, Curl.Easy
import URIs: URI
import Logging


## Structs

"""
    mutable struct SFTP

`SFTP` manages the connection to the server and stores all relevant connection data.

# Constructors

    SFTP(url::AbstractString, username::AbstractString, public_key_file::AbstractString, public_key_file::AbstractString; kwargs) -> SFTP
    SFTP(url::AbstractString, username::AbstractString, password::AbstractString=""; kwargs) -> SFTP

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


"""
    struct SFTPStatStruct

Hold information for file system objects on a Server.

# Fields

- `desc::String`: file or folder description/name
- `mode::UInt`: file system object type (file, folder, etc.)
- `nlink::Int`: number of hard links (contents)
- `uid::String`: numeric user ID of the owner of the file/folder
- `uid::String`: numeric group ID (gid) for the file/folder
- `size::Int64`: file/folder size in Byte
- `mtime::Float64`: modified time


# Constructors

    SFTPStatStruct(stats::AbstractString) -> SFTPStatStruct

Parse the `stats` string and return an `SFTPStatStruct`.

The `stats` is of the format:

    "d--x--x---  151 ftp      ftp          8192 Dec  2  2023 .."
"""
struct SFTPStatStruct
    desc::String
    mode::UInt
    nlink::Int
    uid::String
    gid::String
    size::Int64
    mtime::Float64
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
    # Setup Downloader and URI
    downloader = Downloader()
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
    # Setup Downloader and URI
    downloader = Downloader()
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


# See SFTPStatStruct struct for help/docstrings
function SFTPStatStruct(stats::AbstractString)::SFTPStatStruct
    stats = split.(stats, limit = 9)
    SFTPStatStruct(stats[9], parse_mode(stats[1]), parse(Int64, stats[2]), stats[3], stats[4],
        parse(Int64, stats[5]), parse_date(stats[6], stats[7], stats[8]))
end


## Overload Base functions

Base.show(io::IO, sftp::SFTP) =  println(io, "SFTP(\"$(sftp.username)@$(sftp.uri.host)\")")

Base.broadcastable(sftp::SFTP) = Ref(sftp)


## Helper functions for processing of server paths

#¡ Trailing slashes needed for StatStruct!
"""
    set_url(url::URI) -> URI

Ensure URI path with trailing slash.
"""
function set_url(url::AbstractString)::URI
    uri = URI(url)
    path = isdirpath(uri.path) ? uri.path : uri.path * '/'
    URIs.resolvereference(uri, URIs.escapepath(path))
end


"""
    change_uripath(sftp::SFTP, path::AbstractString) -> URI

Return an updated URI struct based on the `sftp` URI with the given `path`.

Note: The URI stored in `sftp` itself is not updated.
"""
function change_uripath(sftp::SFTP, path::AbstractString)::URI
    isdirpath(path) || (path *= "/")
    URIs.resolvereference(sftp.uri, URIs.escapepath(path))
end


## Helper functions for SFTP struct and fingerprints

"""
    check_and_create_fingerprint(host::AbstractString) -> Nothing

Check for `host` in known_hosts.
"""
function check_and_create_fingerprint(host::AbstractString)::Nothing
    try
        # Try to read known_hosts file
        known_hosts_file = joinpath(homedir(), ".ssh", "known_hosts")
        rows=CSV.File(known_hosts_file;delim=" ",types=String,header=false)
        # Scan known hosts for current host
        for row in rows
            row[1] != host && continue
            @info "$host found host in known_hosts"
            # check the entry we found
            fingerprint_algo = row[2]
            #These are known to work
            if (fingerprint_algo == "ecdsa-sha2-nistp256" || fingerprint_algo == "ecdsa-sha2-nistp256" ||
                fingerprint_algo ==  "ecdsa-sha2-nistp521"  || fingerprint_algo == "ssh-rsa" )
                return
            else
                @warn "correct fingerprint not found in known_hosts"
            end
        end
        @info "Creating fingerprint" host
        create_fingerprint(host)
    catch error
        @warn "An error occurred during fingerprint check; creating a new fingerprint" error
        create_fingerprint(host)
    end
end


"""
    create_fingerprint(host::AbstractString) -> Nothing

Create a new entry in known_hosts for `host`.
"""
function create_fingerprint(host::AbstractString)::Nothing
    # Check for .ssh/known_hosts and create if missing
    sshdir = mkpath(joinpath(homedir(), ".ssh"))
    known_hosts = joinpath(sshdir, "known_hosts")
    # Import ssh key as trusted key or throw error (except for known test issue)
    keyscan = ""
    try
        keyscan = readchomp(`ssh-keyscan -t ssh-rsa $(host)`)
    catch
        @error "keyscan failed; check if ssh-keyscan is installed"
        if host == "test.rebex.net"
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


## Helper functions Curl options

"""
    set_stdopt(sftp::SFTP, easy::Easy) -> Nothing

Set defaults for a number of curl `easy` options as defined by the `sftp` client.
"""
function set_stdopt(sftp::SFTP, easy::Easy)::Nothing
    # User credentials
    isempty(sftp.username) || Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_USERNAME, sftp.username)
    isempty(sftp.password) || Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_PASSWORD, sftp.password)
    # Verifications
    sftp.disable_verify_host && Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_SSL_VERIFYHOST , 0)
    sftp.disable_verify_peer && Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_SSL_VERIFYPEER , 1)
    # Certificates
    isempty(sftp.public_key_file) || Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_SSH_PUBLIC_KEYFILE, sftp.public_key_file)
    isempty(sftp.private_key_file) || Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_SSH_PRIVATE_KEYFILE, sftp.private_key_file)
    # Verbosity
    sftp.verbose && Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_VERBOSE, 1)
    return
end


"""
    reset_easy_hook(sftp::SFTP) -> Nothing

Reset curl `easy` options to standard as defined by the `sftp` client.
"""
function reset_easy_hook(sftp::SFTP)::Nothing
    downloader = sftp.downloader
    downloader.easy_hook = (easy::Easy, info) -> begin
        set_stdopt(sftp, easy)
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_DIRLISTONLY, 1)
    end
    return
end


## Helper functions for path stats

"""
    statscan(sftp::SFTP, path::AbstractString="."; show_cwd_and_parent::Bool=false) -> Vector{SFTPStatStruct}

Like stat, but returns a Vector of `SFTPStatStruct`.

Note that you can only run this on directories.

If `show_cwd_and_parent` is set to `true`, the `SFTPStatStruct` vector includes entries for
`"."` and `".."` on position 1 and 2, respectively.
"""
function statscan(sftp::SFTP, path::AbstractString="."; show_cwd_and_parent::Bool=false)::Vector{SFTPStatStruct}
    # Easy hook for current session
    sftp.downloader.easy_hook = (easy::Easy, info) -> begin
        set_stdopt(sftp, easy)
    end

    # Get server stats for given path
    url = change_uripath(sftp, path)
    io = IOBuffer();
    try
         Downloads.download(string(url), io; sftp.downloader)
    finally
        reset_easy_hook(sftp)
    end
    # Don't know why this is necessary
    res = String(take!(io))
    io2 = IOBuffer(res)
    stats = readlines(io2; keep=false)

    # Instantiate stat structs
    stats = SFTPStatStruct.(stats)
    # Filter current and parent directory
    if !show_cwd_and_parent
        filter!(s -> s.desc != "." && s.desc != "..", stats)
    end
    return stats
end


"""
    parse_date(month::AbstractString, day::AbstractString, year_or_time::AbstractString) -> Float64

From the abbreviated `month` name, the `day` and the `year_or_time` all given as `String`,
return a unix timestamp.
"""
function parse_date(month::AbstractString, day::AbstractString, year_or_time::AbstractString)::Float64
    # Process date parts
    yearStr::String = occursin(":", year_or_time) ? string(Dates.year(Dates.today())) : year_or_time
    timeStr::String = occursin(":", year_or_time) ? year_or_time : "00:00"
    # Assemble datetime string
    datetime = Dates.DateTime("$month $day $yearStr $timeStr", Dates.dateformat"u d yyyy H:M ")
    # Return unix timestamp
    return Dates.datetime2unix(datetime)
end


"""
    parse_mode(s::AbstractString) -> UInt

From the `AbstractString` `s`, parse the file mode octal number and return as `UInt`.
"""
function parse_mode(s::AbstractString)::UInt
    # Error handling
    if length(s) != 10
        throw(ArgumentError("`s` should be an `AbstractString` of length `10`"))
    end
    # Determine file system object type (dir or file)
    dirChar = s[1]
    dir = (dirChar == 'd') ? 0x4000 : 0x8000

    # Determine owner
    owner = str2number(s[2:4])
    group = str2number(s[5:7])
    anyone = str2number(s[8:10])

    # Return mode as UInt
    return dir + owner * 8^2 + group * 8^1 + anyone * 8^0
end


"""
    str2number(s::AbstractString) -> Int64

Parse the file owner symbols in the string `s` to the corresponding ownership number.
"""
function str2number(s::AbstractString)::Int64
    b1 = (s[1] != '-') ?  4 : 0
    b2 = (s[2] != '-') ?  2 : 0
    b3 = (s[3] != '-') ?  1 : 0
    return b1+b2+b3
end
