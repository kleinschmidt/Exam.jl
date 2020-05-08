
extract_ps(root) = extract_ps!([], root)
extract_ps(doc::HTMLDocument) = extract_ps(doc.root[2])

extract_ps!(accum, elem::HTMLElement{:p}) = push!(accum, elem)
extract_ps!(accum, elem::HTMLElement) = (foreach(x -> extract_ps!(accum, x), elem.children); accum)

function parse(doc; detect_labels=false)
    stack = []
    questions = Question[]

    ps = extract_ps(doc)
    while !is_question(first(ps))
        popfirst!(ps)
    end

    question_counter=0
    response_counter=0

    question_labels = Set([])

    for item in ps
        if is_response(item)
            if !isempty(stack)
                push!(
                    questions,
                    question(
                        copy(stack),
                        [],
                        "$(length(questions)+1)",
                        detect_label = detect_labels
                    )
                )
                empty!(stack)
                response_counter = 'A'

                lab = last(questions).label
                lab ∈ question_labels && @warn "Duplicate label detected: $lab"
                push!(question_labels, lab)
            end

            r = response(item, string(response_counter))
            response_counter += 1

            push!(last(questions).responses, r)
        else
            push!(stack, item)
        end
    end

    return questions

end

read_key(fn) = OrderedDict(map(x -> Pair(split(x)...), readlines(fn)))

rekey(r::Response, correct_lab) =
    Response(r.content, r.label, r.id, r.label == correct_lab)
function rekey!(q::Question, key::AbstractDict)
    if haskey(key, q.label)
        correct = key[q.label]
        any(isequal(correct), getfield.(q.responses, :label)) ||
            @warn "Response not found: $correct"
        q.responses .= rekey.(q.responses, correct)
    else
        @warn "No entry found for question $(q.label)"
    end
end    
rekey!(qs::Vector{Question}, key::AbstractDict) = (rekey!.(qs, Ref(key)); qs)

function cleanup_noneall(q::Question)
    has_none = any(occursin.(r"none of the above"i, q.responses))
    has_all = any(occursin.(r"all of the above"i, q.responses))

    if has_none && has_all
        for r in q.responses
            replace!(r, r"(none of) the above"i => s"\1 these")
            replace!(r, r"(all of) the above"i => s"\1 these (except \"none\")")
        end
    elseif has_none || has_all
        for r in q.responses
            replace!(r, r"(none of) the above"i => s"\1 these")
            replace!(r, r"(all of) the above"i => s"\1 these")
        end
    end

    return q
end
