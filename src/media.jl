
function extract_media(src)
    r = ZipFile.Reader(src)
    media_files = filter(f -> occursin(r"^word/media", f.name), r.files)
    Dict(
        replace(f.name, "word/" => "") => read(f)
        for f
        in r.files
        if occursin(r"^word/media", f.name)
    )
end
