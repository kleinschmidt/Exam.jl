is_question(elem::HTMLElement) = any(is_question, elem.children)
is_question(elem::HTMLText) = occursin(r"^[0-9]+\. ", elem.text)

struct Question
    content
    responses::Vector{Response}
    label
    id
end

function question(contents, responses, label; detect_label=false)
    matched = 0
    for elem in contents
        for node in PreOrderDFS(elem)
            if node isa HTMLText
                m = match(r"([0-9]+)\. ", node.text)
                if detect_label && m !== nothing
                    label = m.captures[1]
                    matched += 1
                end
                node.text = replace(node.text, r"[0-9]+\. " => "")
            end
        end
    end

    detect_label && matched == 0 && @warn "Failed to detect label, using default ($label)"
    matched > 1 && @warn "Multiple lables detected, using last one ($label)"

    Question(contents, responses, label, string(uuid4()))
end

function Base.show(io::IO, q::Question)
    print(io, q.label, ": ")

    for c in q.content
        println(io, c)
    end

    print(io, "\n")

    for r in q.responses
        println(io, "  ", r)
    end
end
