


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
    # ¡Not sure why the unused info param is needed, but otherwise walkdir will not work!
    sftp.downloader.easy_hook = (easy::Easy, info) -> begin
        set_stdopt(sftp, easy)
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


function myjoinpath(path::AbstractString, name::AbstractString)
    path == "." && return name
    path * "/" * name * "/"
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

        content = tryf2(statscan, sftp , root)
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


# TODO Update docstring
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
    filename::AbstractString,
    output::String = ""
)::String
    # Define output
    output = isempty(output) ? tempname() : normpath(output, basename(filename))
    # Error handling for existing folders/files
    if isdir(output)
        @error "the specified download file is a directory and cannot be overwritten"
        return output
    elseif isfile(output)
        @warn "specified download file already exists; overwrite (y/n)?"
        confirm = readline()
        while true
            if startswith(lowercase(confirm), "y")
                break
            elseif startswith(lowercase(confirm), "n")
                return output
            end
        end
    end

    # Download file
    uri = URIs.resolvereference(sftp.uri, URIs.escapeuri(filename))
    Downloads.download(string(uri), output; sftp.downloader)
    return output
end


"""
    readdir(sftp::SFTP, join::Bool = false, sort::Bool = true)

Reads the current directory. Returns a vector of Strings just like the regular readdir function.
"""
function Base.readdir(sftp::SFTP, join::Bool = false, sort::Bool = true)
    output = nothing
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
end


"""
    cd(sftp::SFTP, dir::AbstractString)

Change the directory for the SFTP client.
"""
function Base.cd(sftp::SFTP, dir::AbstractString)
    prev_url = sftp.uri
    try
        # Change server path and save in sftp
        url = change_uripath(sftp, dir)
        sftp.uri = url
        readdir(sftp)
    catch
        # Ensure previous url on error
        sftp.uri = prev_url
        rethrow()
    end
    return
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
