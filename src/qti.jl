function qti(qs, id)
    xdoc = XMLDocument()
    root = create_root(xdoc, "questestinterop")
    set_attributes(
        root,
        Dict(
            "xmlns"=>"http://www.imsglobal.org/xsd/ims_qtiasiv1p2",
            "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
            "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd"
        )
    )

    assessment = new_child(root, "assessment")
    set_attribute(assessment, "id", id)

    section = new_child(assessment, "section")
    set_attribute(section, "ident", "root_section")

    for q in qs
        item = new_child(section, "item")
        set_attributes(
            item,
            Dict(
                "ident" => q.id
            )
        )

        ## metadata
        itemmetadata = new_child(item, "itemmetadata")
        qtimetadata = new_child(itemmetadata, "qtimetadata")
        fields = [
            "question_type" => "multiple_choice_question"
        ]
        for field in fields
            xfield = new_child(qtimetadata, "qtimetadatafield")
            lab = new_child(xfield, "fieldlabel")
            add_text(lab, first(field))
            entry = new_child(xfield, "fieldentry")
            add_text(entry, last(field))
        end

        ## presentation
        pres = new_child(item, "presentation")
        mat = new_child(pres, "material")
        mattext = new_child(mat, "mattext")
        set_attributes(
            mattext,
            Dict(
                "texttype" => "text/html"
            )
        )
        for c in q.content
            add_text(mattext, string(c))
        end

        respid = "response1"
        response_lid = new_child(pres, "response_lid")
        set_attributes(
            response_lid,
            Dict(
                "ident" => respid,
                "rcardinality" => "Single"
            )
        )

        render_choice = new_child(response_lid, "render_choice")

        for r in q.responses
            response_label = new_child(render_choice, "response_label")
            set_attribute(response_label, "ident", r.id)

            mat = new_child(response_label, "material")
            mattext = new_child(mat, "mattext")
            set_attributes(
                mattext,
                Dict(
                    "texttype" => "text/html"
                )
            )
            add_text(mattext, string(r.content))
        end

        # correct response...
        correct = q.responses[something(findfirst(x -> x.correct, q.responses), 1)]
        
        resproc = new_child(item, "resproessing")
        outcomes = new_child(resproc, "outcomes")
        decvar = new_child(outcomes, "decvar")
        set_attributes(
            decvar,
            Dict(
                "maxvalue" => "100",
                "minvalue" => "0",
                "varname" => "SCORE",
                "vartype" => "Decimal"
            )
        )

        respcond = new_child(resproc, "respcondition")
        set_attribute(respcond, "continue", "No")
        condvar = new_child(respcond, "conditionvar")
        vareq = new_child(condvar, "varequal")
        set_attribute(vareq, "respident", "response1")
        add_text(vareq, correct.id)

        setvar = new_child(respcond, "setvar")
        set_attributes(
            setvar,
            Dict(
                "action" => "Set",
                "varname" => "SCORE"
            )
        )
        add_text(setvar, "100")

    end
    return(xdoc)
end

function package(name, qs::Pair...; media=Dict())

    package_dir = joinpath("imports", string(name))
    if !isdir(package_dir)
        try
            mkpath(package_dir)
        catch
            @warn "couldn't create package dir $package_dir"
        end
    end

    manifest_xdoc = XMLDocument()
    manifest = create_root(manifest_xdoc, "manifest")
    set_attributes(
        manifest,
        Dict(
            "identifier"=>"gb89c8d93f022f423d433a803104bde1a",
            "xmlns" => "http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1",
            "xmlns:lom" => "http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource",
            "xmlns:imsmd" => "http://www.imsglobal.org/xsd/imsmd_v1p2",
            "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
            "xsi:schemaLocation" => "http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1 http://www.imsglobal.org/xsd/imscp_v1p1.xsd http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lomresource_v1p0.xsd http://www.imsglobal.org/xsd/imsmd_v1p2 http://www.imsglobal.org/xsd/imsmd_v1p2p2.xsd"
        )
    )

    println("Packaging resources:")

    new_child(manifest, "organizations")
    resources = new_child(manifest, "resources")
    res = new_child(resources, "resource")
    set_attributes(
        res,
        Dict(
            "identifier" => name,
            "type" => "imsqti_xmlv1p2"
        )
    )

    for (name, q) in qs
        q_xml = qti(q, name)
        filename = "$name.xml"
        save_file(q_xml, joinpath(package_dir, filename))

        println("✔ $(length(q)) questions → $filename")

        file = new_child(res, "file")
        set_attribute(file, "href", filename)
    end

    for (name, src) in media
        println("✔ $name")
        dest = joinpath(package_dir, name)
        isdir(dirname(dest)) || mkpath(dirname(dest))
        write(dest, src)

        file = new_child(res, "file")
        set_attribute(file, "href", name)
    end

    save_file(manifest_xdoc, joinpath(package_dir, "imsmanifest.xml"))
    run(`zip -r imports/$name.qti.zip $package_dir`)

end
