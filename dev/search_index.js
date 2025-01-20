var documenterSearchIndex = {"docs":
[{"location":"troubleshooting/#Troubleshooting","page":"Troubleshooting","title":"Troubleshooting","text":"","category":"section"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"If you get: RequestError: Failure establishing ssh session: -5, Unable to exchange encryption keys while requesting... Try and upgrade to Julia 1.9.4. It seems to be a bug in an underlying library.","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"If it does not work, check your known_hosts file in your .ssh directory. ED25519 keys do not seem to work.","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"Use the ssh-keyscan tool: From command line, execute: ssh-keyscan [hostname]. Add the ecdsa-sha2-nistp256 line to your knownhosts file. This file is located in your .ssh-directory. This is directory is located in C:\\Users\\{youruser}\\.ssh on Windows and ~/.ssh on Linux.","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"___Note: Setting up certificate authentication___","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"To set up certificate authentication, create the certificates in the ~/.ssh/idrsa and ~/.ssh/idrsa.pub files. On Windows these are located in C:\\Users\\{your user}\\.ssh. ","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"Then use the function  sftp = SFTP(\"sftp://mysitewhereIhaveACertificate.com\", \"myuser\") to create a SFTP type.","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"Example files","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"___in \"known_hosts\"___ mysitewhereIhaveACertificate.com ssh-rsa sdsadxcvacvljsdflsajflasjdfasldjfsdlfjsldfj","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"___in \"id_rsa\"___","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"––-BEGIN RSA PRIVATE KEY––- ..... cu1sTszTVkP5/rL3CbI+9rgsuCwM67k3DiH4JGOzQpMThPvolCg=","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"––-END RSA PRIVATE KEY––-","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"___in id_rsa.pub___ ssh-rsa AAAAB3...SpjX/4t Comment here","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"After setting up the files, test using your local sftp client:","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"ssh myuser@mysitewhereIhaveACertificate.com","category":"page"},{"location":"reference/#SFTPClient-API-Documentation","page":"SFTPClient API Documentation","title":"SFTPClient API Documentation","text":"","category":"section"},{"location":"reference/","page":"SFTPClient API Documentation","title":"SFTPClient API Documentation","text":"Modules = [SFTPClient]\nOrder   = [:function, :type]","category":"page"},{"location":"reference/#Base.Filesystem.cd-Tuple{SFTP, AbstractString}","page":"SFTPClient API Documentation","title":"Base.Filesystem.cd","text":"cd(sftp::SFTP, dir::AbstractString)\n\nChange to dir in the uri of the sftp client.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.Filesystem.filemode-Tuple{SFTPStatStruct}","page":"SFTPClient API Documentation","title":"Base.Filesystem.filemode","text":"Base.isdir(st::SFTPStatStruct) -> UInt\n\nReturn the filemode in the SFTPStatStruct.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.Filesystem.isdir-Tuple{SFTPStatStruct}","page":"SFTPClient API Documentation","title":"Base.Filesystem.isdir","text":"isdir(st::SFTPStatStruct) -> Bool\n\nAnalyse the SFTPStatStruct and return true for a directory, false otherwise.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.Filesystem.isfile-Tuple{SFTPStatStruct}","page":"SFTPClient API Documentation","title":"Base.Filesystem.isfile","text":"isfile(st::SFTPStatStruct) -> Bool\n\nAnalyse the SFTPStatStruct and return true for a file, false otherwise.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.Filesystem.islink-Tuple{SFTPStatStruct}","page":"SFTPClient API Documentation","title":"Base.Filesystem.islink","text":"islink(st::SFTPStatStruct) -> Bool\n\nAnalyse the SFTPStatStruct and return true for a symbolic link, false otherwise.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.Filesystem.mkdir-Tuple{SFTP, AbstractString}","page":"SFTPClient API Documentation","title":"Base.Filesystem.mkdir","text":"mkdir(sftp::SFTP, dir::AbstractString)\n\nCreate a directory dir in the uri of the sftp client.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.Filesystem.mv-Tuple{SFTP, AbstractString, AbstractString}","page":"SFTPClient API Documentation","title":"Base.Filesystem.mv","text":"mv(\n    sftp::SFTP,\n    old_name::AbstractString,\n    new_name::AbstractString;\n)\n\nMove, i.e. rename, the file from old_name to new_name in the uri of the sftp client.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.Filesystem.pwd-Tuple{SFTP}","page":"SFTPClient API Documentation","title":"Base.Filesystem.pwd","text":"pwd(sftp::SFTP) -> String\n\nReturn the current URI path of the SFTP client.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.Filesystem.readdir","page":"SFTPClient API Documentation","title":"Base.Filesystem.readdir","text":"readdir(sftp::SFTP, join::Bool = false, sort::Bool = true)\n\nReads the current directory. Returns a vector of Strings just like the regular readdir function.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Base.Filesystem.rm-Tuple{SFTP, AbstractString}","page":"SFTPClient API Documentation","title":"Base.Filesystem.rm","text":"rm(sftp::SFTP, file::AbstractString)\n\nRemove (delete) the file in the uri of the sftp client.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.Filesystem.splitdir","page":"SFTPClient API Documentation","title":"Base.Filesystem.splitdir","text":"splitdir(sftp::SFTP, path::AbstractString=\".\") -> Tuple{URI,String}\n\nJoin the path with the path of the URI in sftp and then split it into the directory name and base name. Return a Tuple of URI with the split path and a String with the base name.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Base.Filesystem.walkdir","page":"SFTPClient API Documentation","title":"Base.Filesystem.walkdir","text":"walkdir(\n    sftp::SFTP,\n    root::AbstractString=\".\";\n    topdown::Bool=true,\n    follow_symlinks::Bool=false,\n    sort::Bool=true\n) -> Channel{Tuple{String,Vector{String},Vector{String}}}\n\nReturn an iterator that walks the directory tree of the given root of the sftp client. If the root is ommitted, the current URI path of the sftp client is used. The iterator returns a tuple containing (rootpath, dirs, files). The iterator starts at the root unless topdown is set to false. If follow_symlinks is set to true, the sources of symlinks are listed rather than the symlink itself as file. If sort is set to true, the files and directories are listed alphabetically.\n\nExamples\n\nfor (root, dirs, files) in walkdir(sftp, \"/\")\n    println(\"Directories in $root\")\n    for dir in dirs\n        println(joinpath(root, dir)) # path to directories\n    end\n    println(\"Files in $root\")\n    for file in files\n        println(joinpath(root, file)) # path to files\n    end\nend\n\n\n\n\n\n","category":"function"},{"location":"reference/#Base.download","page":"SFTPClient API Documentation","title":"Base.download","text":"download(\n    sftp::SFTP,\n    filename::AbstractString,\n    output::String = \"\"\n) -> String\n\nDownload a file from the sftp server. The specified filename may include a path on the remote server, which is ignored on the local system.\n\nThe file can be downloaded and saved directly to a variable or it can be saved to a file in the output directory.\n\nExample\n\nsftp = SFTP(\"sftp://test.rebex.net/pub/example/\", \"demo\", \"password\")\nfiles=readdir(sftp)\ndownload_dir=\"/tmp\"\nSFTPClient.download.(sftp, files, download_dir)\n````\n\nYou can also use it like this:\n\njulia df=DataFrame(CSV.File(SFTPClient.download(sftp, \"/mydir/test.csv\"))) ```\n\n\n\n\n\n","category":"function"},{"location":"reference/#Base.isequal-Tuple{SFTPStatStruct, SFTPStatStruct}","page":"SFTPClient API Documentation","title":"Base.isequal","text":"isequal(a::SFTPStatStruct, b::SFTPStatStruct) -> Bool\n\nComares equality between the description (desc fields) of two SFTPStatStruct objects and returns true for equality, otherwise false.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.isless-Tuple{SFTPStatStruct, SFTPStatStruct}","page":"SFTPClient API Documentation","title":"Base.isless","text":"isless(a::SFTPStatStruct, b::SFTPStatStruct) -> Bool\n\nComares the descriptions (desc fields) of two SFTPStatStruct objects and returns true, if a is lower than b, otherwise false.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Base.stat","page":"SFTPClient API Documentation","title":"Base.stat","text":"stat(sftp::SFTP, path::AbstractString=\".\") -> SFTPStatStruct\n\nReturn the stat data for path on the sftp server.\n\nNote: This returns only stat data for one object, but stat data for all objects in the same folder is obtained internally. If you need stat data for more than object in the same folder, use statscan for better performance and reduced connections to the server.\n\n\n\n\n\n","category":"function"},{"location":"reference/#SFTPClient.change_uripath-Tuple{URIs.URI, Vararg{AbstractString}}","page":"SFTPClient API Documentation","title":"SFTPClient.change_uripath","text":"change_uripath(uri::URI, path::AbstractString; isfile::Bool=false) -> URI\n\nReturn an updated uri struct with the given path. Set isfile to true, if the path is a file to omit the trailing slash.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.check_and_create_fingerprint-Tuple{AbstractString}","page":"SFTPClient API Documentation","title":"SFTPClient.check_and_create_fingerprint","text":"check_and_create_fingerprint(host::AbstractString) -> Nothing\n\nCheck for host in known_hosts.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.create_fingerprint-Tuple{AbstractString}","page":"SFTPClient API Documentation","title":"SFTPClient.create_fingerprint","text":"create_fingerprint(host::AbstractString) -> Nothing\n\nCreate a new entry in known_hosts for host.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.findbase-Tuple{Vector{SFTPStatStruct}, AbstractString, AbstractString}","page":"SFTPClient API Documentation","title":"SFTPClient.findbase","text":"findbase(stats::Vector{SFTPStatStruct}, base::AbstractString, path::AbstractString) -> Int\n\nReturn the index of base in stats or throw and PathNotFoundError, if base is not found.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.ftp_command-Tuple{SFTP, String}","page":"SFTPClient API Documentation","title":"SFTPClient.ftp_command","text":"ftp_command(sftp::SFTP, command::String)\n\nExecute the command on the sftp server.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.linkerror-Tuple{String}","page":"SFTPClient API Documentation","title":"SFTPClient.linkerror","text":"linkerror(link::String) -> Nothing\n\nShow an error for an anticipated link format.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.parse_date-Tuple{AbstractString, AbstractString, AbstractString}","page":"SFTPClient API Documentation","title":"SFTPClient.parse_date","text":"parse_date(month::AbstractString, day::AbstractString, year_or_time::AbstractString) -> Float64\n\nFrom the abbreviated month name, the day and the year_or_time all given as String, return a unix timestamp.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.parse_mode-Tuple{AbstractString}","page":"SFTPClient API Documentation","title":"SFTPClient.parse_mode","text":"parse_mode(s::AbstractString) -> UInt\n\nFrom the AbstractString s, parse the file mode octal number and return as UInt.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.reset_easy_hook-Tuple{SFTP}","page":"SFTPClient API Documentation","title":"SFTPClient.reset_easy_hook","text":"reset_easy_hook(sftp::SFTP) -> Nothing\n\nReset curl easy options to standard as defined by the sftp client.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.rmdir-Tuple{SFTP, AbstractString}","page":"SFTPClient API Documentation","title":"SFTPClient.rmdir","text":"rmdir(sftp::SFTP, dir::AbstractString)\n\nRemove (delete) the directory dir in the uri of the sftp client.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.set_stdopt-Tuple{SFTP, Downloads.Curl.Easy}","page":"SFTPClient API Documentation","title":"SFTPClient.set_stdopt","text":"set_stdopt(sftp::SFTP, easy::Easy) -> Nothing\n\nSet defaults for a number of curl easy options as defined by the sftp client.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.set_url-Tuple{AbstractString}","page":"SFTPClient API Documentation","title":"SFTPClient.set_url","text":"set_url(url::URI) -> URI\n\nEnsure URI path with trailing slash.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.statscan","page":"SFTPClient API Documentation","title":"SFTPClient.statscan","text":"statscan(\n    sftp::SFTP,\n    path::AbstractString=\".\";\n    sort::Bool=true,\n    show_cwd_and_parent::Bool=false\n) -> Vector{SFTPStatStruct}\n\nLike stat, but returns a Vector of SFTPStatStruct with filesystem stats for all objects in the given path.\n\n** This should be preferred over stat for performance reasons. **\n\nNote that you can only run this on directories.\n\nBy default, the SFTPStatStruct vector is sorted by the descriptions (desc fields). For large folder contents, sort can be set to false to increase performance, if the output order is irrelevant. If show_cwd_and_parent is set to true, the SFTPStatStruct vector includes entries for \".\" and \"..\" on position 1 and 2, respectively.\n\n\n\n\n\n","category":"function"},{"location":"reference/#SFTPClient.str2number-Tuple{AbstractString}","page":"SFTPClient API Documentation","title":"SFTPClient.str2number","text":"str2number(s::AbstractString) -> Int64\n\nParse the file owner symbols in the string s to the corresponding ownership number.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.symlink_source!-Tuple{SFTP, AbstractString, @NamedTuple{dirs::Vector{String}, files::Vector{String}, scans::Dict{String, Any}}, Bool}","page":"SFTPClient API Documentation","title":"SFTPClient.symlink_source!","text":"symlink_source!(\n    sftp::SFTP,\n    link::AbstractString,\n    pathobjects::@NamedTuple{dirs::Vector{String},files::Vector{String},scans::Dict{String,Any}},\n    follow_symlinks::Bool\n) -> Nothing\n\nAnalyse the symbolic link on the sftp server and add it to the respective pathobjects list. Save the source of the symlink, if follow_symlinks is set to true, otherwise save symlinks as files.\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.unescape_joinpath-Tuple{SFTP, AbstractString}","page":"SFTPClient API Documentation","title":"SFTPClient.unescape_joinpath","text":"unescape_joinpath(sftp::SFTP, path::AbstractString) -> String\n\nJoin the path with the URI path  in sftp and return the unescaped path. Note, this function should not use URL:s since CURL:s api need spaces\n\n\n\n\n\n","category":"method"},{"location":"reference/#SFTPClient.upload","page":"SFTPClient API Documentation","title":"SFTPClient.upload","text":"upload(\n    sftp::SFTP,\n    file::AbstractString;\n    remote_dir::AbstractString=\".\",\n    local_dir::AbstractString=\".\"\n) -> Nothing\n\nUpload (put) a file on the server. If file includes a path, this is where it is put on the server. The path may be relative to the current uri path of the sftp server or absolute. On the local system, a path may be specified as last argument.\n\nExamples\n\nupload(sftp, \"test.csv\", \"/tmp\")\n\nfiles=readdir()\nupload.(sftp, files)\n\n\n\n\n\n","category":"function"},{"location":"reference/#SFTPClient.PathNotFoundError","page":"SFTPClient API Documentation","title":"SFTPClient.PathNotFoundError","text":"PathNotFoundError(path)\n\nThe path (file or folder) was not found.\n\n\n\n\n\n","category":"type"},{"location":"reference/#SFTPClient.SFTP","page":"SFTPClient API Documentation","title":"SFTPClient.SFTP","text":"mutable struct SFTP\n\nSFTP manages the connection to the server and stores all relevant connection data.\n\nConstructors\n\nSFTP(url::AbstractString, username::AbstractString, public_key_file::AbstractString, public_key_file::AbstractString; kwargs) -> SFTP\nSFTP(url::AbstractString, username::AbstractString, password::AbstractString=\"\"; kwargs) -> SFTP\n\nConstruct an SFTP client from the url and either user information or public and private key file.\n\nArguments\n\nurl: The url to connect to, e.g., sftp://mysite.com\nusername/password: user credentials\npublic_key_file/public_key_file: authentication certificates\n\nKeyword arguments\n\ncreate_known_hosts_entry: Automatically create an entry in known hosts\ndisable_verify_peer: verify the authenticity of the peer's certificate\ndisable_verify_host: verify the host in the server's TLS certificate\nverbose: display a lot of verbose curl information\n\nImportant notice\n\nA username must be provided for both methods to work.\n\nBefore using the constructor method for certificate authentication, private and public key files must be created and stored in the ~/.ssh folder and on the server, e.g. ~/.ssh/idrsa and ~/.ssh/idrsa.pub. Additionally, the host must be added to the known_hosts file in the ~/.ssh folder.\n\nThe correct setup can be tested in the terminal with ssh myuser@mysitewhereIhaveACertificate.com.\n\nExamples\n\nsftp = SFTP(\"sftp://mysitewhereIhaveACertificate.com\", \"myuser\", \"test.pub\", \"test.pem\")\nsftp = SFTP(\"sftp://mysitewhereIhaveACertificate.com\", \"myuser\")\nsftp = SFTP(\"sftp://test.rebex.net\", \"demo\", \"password\")\n\n\n\n\n\n","category":"type"},{"location":"reference/#SFTPClient.SFTPStatStruct","page":"SFTPClient API Documentation","title":"SFTPClient.SFTPStatStruct","text":"struct SFTPStatStruct\n\nHold information for file system objects on a Server.\n\nFields\n\ndesc::String: file or folder description/name\nmode::UInt: file system object type (file, folder, etc.)\nnlink::Int: number of hard links (contents)\nuid::String: numeric user ID of the owner of the file/folder\nuid::String: numeric group ID (gid) for the file/folder\nsize::Int64: file/folder size in Byte\nmtime::Float64: modified time\n\nConstructors\n\nSFTPStatStruct(stats::AbstractString) -> SFTPStatStruct\n\nParse the stats string and return an SFTPStatStruct.\n\nThe stats are of the format:\n\n\"d--x--x---  151 ftp      ftp          8192 Dec  2  2023 ..\"\n\n\n\n\n\n","category":"type"},{"location":"#Julia-SFTP-Client","page":"Home","title":"Julia SFTP Client","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"An SFTP Client for Julia.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A julia package for communicating with SFTP Servers, supporting username and password, or certificate authentication. ","category":"page"},{"location":"#SFTPClient-Features","page":"Home","title":"SFTPClient Features","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"- readdir\n- download\n- upload \n- cd\n- rm \n- rmdir\n- mkdir\n- mv\n- sftpstat (like stat, but more limited)","category":"page"},{"location":"#SFTPClient-Installation","page":"Home","title":"SFTPClient Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Install by running:","category":"page"},{"location":"","page":"Home","title":"Home","text":"import Pkg;Pkg.add(\"SFTPClient\")","category":"page"},{"location":"#SFTPClient-Examples","page":"Home","title":"SFTPClient Examples","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"\n    using SFTPClient\n    sftp = SFTP(\"sftp://test.rebex.net/pub/example/\", \"demo\", \"password\")\n    files=readdir(sftp)\n    # On Windows, replace this with an appropriate path\n    downloadDir=\"/tmp/\"\n    SFTPClient.download.(sftp, files, downloadDir=downloadDir)\n","category":"page"},{"location":"","page":"Home","title":"Home","text":"    #You can also use it like this\n    df=DataFrame(CSV.File(SFTPClient.download(sftp, \"/mydir/test.csv\")))\n\n    # For certificate authentication, you can do this (since 0.3.8)\n    sftp = SFTP(\"sftp://mysitewhereIhaveACertificate.com\", \"myuser\", \"cert.pub\", \"cert.pem\")\n   \n    # The cert.pem is your certificate (private key), and the cert.pub can be obtained from the private # key as following: ssh-keygen -y  -f ./cert.pem. Save the output into \"cert.pub\". \n","category":"page"}]
}
