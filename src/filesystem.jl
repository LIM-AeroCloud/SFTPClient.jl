"""
    pwd(sftp::SFTP) -> String

Return the current URI path of the SFTP client.
"""
Base.pwd(sftp::SFTP)::String = isempty(sftp.uri.path) ? "/" : sftp.uri.path


"""
    walkdir(
        sftp::SFTP,
        root::AbstractString=".";
        topdown::Bool=true,
        follow_symlinks::Bool=false,
        sort::Bool=true
    ) -> Channel{Tuple{String,Vector{String},Vector{String}}}

Return an iterator that walks the directory tree of the given `root` of the `sftp` client.
If the `root` is ommitted, the current URI path of the `sftp` client is used.
The iterator returns a tuple containing `(rootpath, dirs, files)`.
The iterator starts at the `root` unless `topdown` is set to `false`.
If `follow_symlinks` is set to `true`, the sources of symlinks are listed rather
than the symlink itself as file. If `sort` is set to `true`, the files and directories
are listed alphabetically.

# Examples

```julia
for (root, dirs, files) in walkdir(sftp, "/")
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
function Base.walkdir(
    sftp::SFTP,
    root::AbstractString=".";
    topdown::Bool=true,
    follow_symlinks::Bool=false,
    sort::Bool=true
)::Channel{Tuple{String,Vector{String},Vector{String}}}
    function _walkdir(chnl, root)::Nothing
        # Init
        uri = change_uripath(sftp.uri, root)
        pathobjects = (;
            dirs = Vector{String}(),
            files = Vector{String}(),
            scans = Dict{String,Any}()
        )
        # Get stats on current folder
        scans = statscan(sftp, uri.path; sort)
        # Loop over stats of current folder
        for statstruct in scans
            name = statstruct.desc
            # Handle symbolic links and assign files and folders
            if islink(statstruct)
                symlink_source!(sftp, name, pathobjects, follow_symlinks)
            elseif isdir(statstruct)
                push!(pathobjects.dirs, name)
            elseif isfile(statstruct)
                push!(pathobjects.files, name)
            else
                @warn "skipping path object of unknown mode" name
            end
        end
        # Save path objects top-down
        if topdown
            push!(chnl, (uri.path, pathobjects.dirs, pathobjects.files))
        end
        # Scan subdirectories recursively
        for dir in pathobjects.dirs
            _walkdir(chnl, joinpath(uri, dir).path)
        end
        # Save path objects bottom-up
        if !topdown
            push!(chnl, (uri.path, pathobjects.dirs, pathobjects.files))
        end
        return
    end
    return Channel{Tuple{String,Vector{String},Vector{String}}}(chnl -> _walkdir(chnl, root))
end


"""
    symlink_source!(
        sftp::SFTP,
        link::AbstractString,
        pathobjects::@NamedTuple{dirs::Vector{String},files::Vector{String},scans::Dict{String,Any}},
        follow_symlinks::Bool
    ) -> Nothing

Analyse the symbolic `link` on the `sftp` server and add it to the respective `pathobjects` list.
Save the source of the symlink, if `follow_symlinks` is set to `true`, otherwise save symlinks as files.
"""
function symlink_source!(
    sftp::SFTP,
    link::AbstractString,
    pathobjects::@NamedTuple{dirs::Vector{String},files::Vector{String},scans::Dict{String,Any}},
    follow_symlinks::Bool
)::Nothing
    # Split file name and link source
    linkparts = split(link, "->") .|> strip

    # Get file name and source path of symlink
    file, source = linkparts
    uri, base = splitdir(sftp, source)
    # Check correct link format
    if isempty(linkparts)
        return linkerror(link)
    elseif length(linkparts) ≠ 2
        push!(pathobjects.files, file)
        return linkerror(link)
    # Add link to files and return, if not following symlinks
    elseif !follow_symlinks
        push!(pathobjects.files, file)
        return
    end
    if uri.path ∉ keys(pathobjects.scans)
        # Get stats for containing source folder
        linkscans = statscan(sftp, uri.path)
        pathobjects.scans[uri.path] = Dict(getfield.(linkscans, :desc) .=> linkscans)
    end
    # Add link source to pathobjects
    try
        isdir(pathobjects.scans[uri.path][base]) ?
            push!(pathobjects.dirs, file) : push!(pathobjects.files, file)
    catch
        push!(pathobjects.files, file)
    end
    return
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
    splitdir(sftp::SFTP, path::AbstractString=".") -> Tuple{URI,String}

Join the `path` with the path of the URI in `sftp` and then split it into the
directory name and base name. Return a Tuple of `URI` with the split path and
a `String` with the base name.
"""
function Base.splitdir(sftp::SFTP, path::AbstractString=".")::Tuple{URI,String}
    # Join the path with the sftp.uri, ensure no trailing slashes in the path
    # ℹ First enforce trailing slashes with joinpath(..., ""), then remove the slash with path[1:end-1]
    path = joinpath(sftp.uri, string(path), "").path[1:end-1]
    # ¡ workaround for URIs joinpath
    startswith(path, "//") && (path = path[2:end])
    # Split directory from base name
    dir, base = splitdir(path)
    # Convert dir to a URI with trailing slash
    joinpath(URI(sftp.uri; path=dir), ""), base
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
    files = readlines(io2; keep=false)

    filter!(x->x ≠ ".." && x ≠ ".", files)

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
        sftp.uri = change_uripath(sftp.uri, dir)
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
