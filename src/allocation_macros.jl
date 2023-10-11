# Helper Macros for checking that a function doesn't allocate memory
# https://forem.julialang.org/dpinol/detecting-test-allocated-gotchas-34op
export @testnoallocations, @is_called_from_function
export _fail_if_non_const_globals_in_expressions, expressionsymbols, iscompileenabled

macro testnoallocations(expressions...)
    if length(expressions) == 0
        throw("testnoallocations requires an expression to test")
    end

    exprs = expressions
    run_twice = true
    if length(expressions) >= 2 && (expressions[1] == :onlyonce || expressions[1] == :noprecompile)
        run_twice = false
        exprs = expressions[2:end]
    end

    # Uncomment the following line if non-const globals should be prohibited
    _fail_if_non_const_globals_in_expressions(__module__, false, expressions...)
    return esc(
        quote
            if (!@is_called_from_function())
                @warn "Since not called from a function @allocated could be imprecise"
                # display(stacktrace())
            end

            if !iscompileenabled()
                @warn "Allocations measures are not precise because executed with --compile=min"
            end

            # Executes the code twice to exclude the allocation cost of the first call
            if $run_twice
                $(exprs...)
            end
            # @test (@allocated $(exprs...)) === 0
            (res, allocs) = count_allocations(() -> begin
                $(exprs...)
            end)

            @test allocs === 0
            res
        end
    )
end

macro is_called_from_function()
    expr = esc(:(
        try
            current_function_name = nameof(var"#self#")
            true
        catch
            false
        end
    ))
    return expr
end

function _fail_if_non_const_globals_in_expressions(mod::Module, only_return_no_error::Bool, expressions...)
    has_non_const = false

    for e in expressions
        non_const_globals = (
            arg for arg in expressionsymbols(e) if isdefined(mod, arg) && !isconst(mod, arg)
        )
        if !isempty(non_const_globals)
            if !only_return_no_error
                error(
                    "testnoallocations called with expression containing non const global symbols $(collect(
                non_const_globals
            ))")
            end
            has_non_const = true
        end
    end

    !has_non_const
end

" Return all the symbols that make up an expression (or itself if a symbol is passed)"
function expressionsymbols(e::Union{Expr,Symbol,Number})
    !isa(e, Expr) && return (ex for ex in (e,) if isa(e, Symbol))
    topSymbols = (arg for arg in e.args if isa(arg, Symbol))
    subExpressions = (expressionsymbols(arg) for arg in e.args if isa(arg, Expr))
    return (topSymbols..., Iterators.flatten(subExpressions)...)
end


iscompileenabled() = Base.JLOptions().compile_enabled == 1