is_question(elem::HTMLElement) = any(is_question, elem.children)
is_question(elem::HTMLText) = occursin(r"^[0-9]+\. ", elem.text)

struct Question
    content
    responses::Vector{Response}
    label
    id
end

function question(contents, responses, label)
    for elem in contents
        for node in PreOrderDFS(elem)
            if node isa HTMLText
                node.text = replace(node.text, r"[0-9]+\. " => "")
            end
        end
    end

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
