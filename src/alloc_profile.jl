export count_allocations

function count_allocations(func::Function, precompile::Bool=true)
    # get own stacktrace to know minimum stack depth
    own_stacktrace = stacktrace()
    own_func_trace = own_stacktrace[1]

    # run function once to precompile
    if precompile
        # TODO: check if it is nessecary to precompile
        func()
    end

    # profile funciton for allocations
    Profile.Allocs.clear()
    res = (Profile.Allocs.@profile sample_rate = 1 func())
    alloc_res = Profile.Allocs.fetch()

    # analyze allocs
    allocs = alloc_res.allocs
    if isempty(allocs)
        return (res, 0)
    end


    tested_func = nothing
    total_allocated = 0
    warn_str = ""
    alloc_map = Dict()

    # check all allocations and deduplicate
    for alloc in allocs
        stack = alloc.stacktrace
        total_allocated += alloc.size

        # find only stacktrace below current function
        last_index = findlast(stack) do st
            st.file == own_func_trace.file && st.func == own_func_trace.func
        end

        # Additonal Stack entries that are added due to the profiling
        additonal_stack_depth = 3
        tested_func = stack[last_index-additonal_stack_depth-1]

        # Test function
        sub_stack = stack[max(1, last_index - WARN_ALLOC_STACK_DEPTH - additonal_stack_depth):last_index-additonal_stack_depth]
        sub_stack_str = ""


        for (i, s) in enumerate(Iterators.reverse(sub_stack))
            sub_stack_str *= "\n$(i == length(sub_stack) ? "└" : "├")$(repeat("─", i)) $(s.func) @ $(s.file):$(s.line)"
        end

        # deduplicate
        (num_calls, amount_allocated, type) = get(alloc_map, sub_stack_str, (0, 0, nothing))
        alloc_map[sub_stack_str] = (num_calls + 1, amount_allocated + alloc.size, alloc.type)
    end

    for (k, v) in alloc_map
        warn_str *= "\n┌ Allocated $(v[3]) ($(v[2]) bytes) [$(v[1])x]" * k
    end

    warn_str = "Detected $(length(allocs)) alocations ($total_allocated bytes) in $(tested_func.func)(...)" * warn_str

    @warn warn_str

    return (res, total_allocated)
end