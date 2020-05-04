read_docx(fn; flags="--self-contained") = read(`pandoc -f docx -t html $flags $fn`, String)
