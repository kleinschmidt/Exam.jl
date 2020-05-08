is_response(elem::HTMLElement) = any(is_response, elem.children)
is_response(elem::HTMLText) = occursin(r"^[A-E]\.", elem.text)

struct Response
    content
    label
    id
    correct
end

function Base.occursin(pat, r::Response)
    for node in PreOrderDFS(r.content)
        if node isa HTMLText
            occursin(pat, node.text) && return true
        end
    end
    return false
end

function Base.replace!(r::Response, rep::Pair)
    for node in PreOrderDFS(r.content)
        if node isa HTMLText
            node.text = replace(node.text, rep)
        end
    end
    return r
end

_isempty(x::HTMLText) = isempty(x.text)
_isempty(x::HTMLElement) = isempty(x.children) || all(isempty(child) for child in x.children)

function cleanup_strong!(elem::HTMLElement)
    if length(elem.children) == 1 && first(elem.children) isa HTMLElement{:strong}
        elem.children = [elem.children[1].children[1]]
    else
        filter!(x -> !(isa(x, HTMLElement{:strong}) && _isempty(x)), elem.children)
    end
    return elem
end

cleanup_strong!(elem::HTMLText) = HTMLText

function response(elem::HTMLElement, label, correct=false)
    elem = deepcopy(elem)
    for node in PostOrderDFS(elem)
        if node isa HTMLText
            node.text = replace(node.text, r"[A-E]+\. ?" => "")
        end
    end

    # re-parse to get rid of any emtpy elements.  children[2] is <body>, children[1] is body contents
    elem = cleanup_strong!(parsehtml(string(elem)).root.children[2].children[1])
    Response(elem, label, string(uuid4()), correct)
end

Base.show(io::IO, r::Response) =
    print(
        io,
        r.correct ? "✔ " : "✘ ",
        r.label, ". ",
        r.content
    )
