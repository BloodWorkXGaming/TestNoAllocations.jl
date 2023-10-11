export count_allocations

function count_allocations(func::Function)
    # get own stacktrace to know minimum stack depth
    own_stacktrace = stacktrace()
    own_func_trace = own_stacktrace[1]

    # run function once to precompile
    func()

    # profile funciton for allocations
    Profile.Allocs.clear()
    Profile.Allocs.@profile sample_rate = 1 func()
    alloc_res = Profile.Allocs.fetch()

    # analyze allocs
    allocs = alloc_res.allocs
    if isempty(allocs)
        return
    end


    tested_func = nothing
    total_allocated = 0
    warn_str = ""
    alloc_map = Dict()

    for alloc in allocs
        stack = alloc.stacktrace
        total_allocated += alloc.size

        last_index = findlast(stack) do st
            st.file == own_func_trace.file && st.func == own_func_trace.func
        end

        @show last_index


        alloc_location = stack[last_index-3]
        tested_func = alloc_location

        alloc_stack_depth = 4
        sub_stack = stack[max(1, last_index - alloc_stack_depth - 3):last_index-3]
        sub_stack_str = ""


        for (i, s) in enumerate(Iterators.reverse(sub_stack))
            sub_stack_str *= "\n$(i == length(sub_stack) ? "└" : "├")$(repeat("─", i)) $(s.func) @ $(s.file):$(s.line)"
        end

        (num_calls, amount_allocated, type) = get(alloc_map, sub_stack_str, (0, 0, nothing))
        alloc_map[sub_stack_str] = (num_calls + 1, amount_allocated + alloc.size, alloc.type)
    end

    for (k, v) in alloc_map
        warn_str *= "\n┌ Allocated $(v[3]) ($(v[2]) bytes) [$(v[1])x]" * k
    end

    warn_str = "Detected $(length(allocs)) alocations ($total_allocated bytes) in $(tested_func.func)(...)" * warn_str

    @warn warn_str

    return
end