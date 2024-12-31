module SFTPClient

include("sftp.jl")
include("filesystem.jl")

export SFTP, readdir, download, upload, cd, rm, rmdir, mkdir, mv, statscan, SFTPStatStruct, isdir, isfile, filemode, walkdir

end # module SFTPClient
