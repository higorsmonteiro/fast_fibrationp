
"""
Put it on UTILS
"""
function array2string(arr::Array)
    final_str = ""
    for j in 1:length(arr)
        final_str = final_str*"$(arr[j])"
    end
    return final_str
end

"""
    Function to compare if two partitions of fibers are equivalent. It is an auxiliary 
    function to be used for unit testing.

    Args:
        part1:

        part2:

    Result:
        equal:
            Boolean value. 'true' if the two parsed partitions are equivalent. 'false'
            otherwise.
"""
function compare_partitions(part1::Array{Fiber}, part2::Array{Fiber})
    return
end