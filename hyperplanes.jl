using JuMP
using Clp
using Simplicial


function subsets(n)
    subsets = []
    for i = 0:2^n-1
        set = []
        bin_str = bin(i, n)
        for i = 1:n
            if bin_str[i]=='1'
                push!(set, i)
            end
        end
        push!(subsets, set)
    end
    return subsets
end



function code_from_hyperplanes(n, d, equations, to_check = subsets(n), checked = [] , constraints = [],  counter = d+1)
    w_sweep = randn(d) #use randn(d)
    new_to_check = []
    new_checked = []
    min_value = 0
    for codeword in to_check
        m = Model(solver = ClpSolver())
        @variable(m, x[1:d])
        affs = []
        consts = []
        for i = 1:n
            push!(affs, AffExpr(x, equations[i][1], equations[i][2]))
        end
        for constraint in constraints
            @constraint(m, AffExpr(x, constraint[1], constraint[2]) == 0)
        end
        for i = 1:n
            if i in codeword
                @constraint(m, affs[i] >= 0)
            else
                @constraint(m, affs[i] <= 0)
            end
        end
        @objective(m, Min, AffExpr(x, w_sweep, 0))
        status = solve(m)
        if status == :Optimal
            push!(new_checked, (codeword, getobjectivevalue(m), counter))
            if getobjectivevalue(m) < min_value
                min_value = getobjectivevalue(m)
            end
        elseif status == :Unbounded
            push!(new_to_check, codeword)
        end
    end
    sort!(new_checked, by = v -> v[2])
    append!(checked, new_checked)
    if length(new_to_check) == 0
        return CombinatorialCode([tuple[1] for tuple in checked])
    elseif counter > 0
         push!(constraints, (w_sweep, -min_value + 1 ))
         return code_from_hyperplanes(n, d, equations, new_to_check, checked, constraints, counter-1)
    end

end
