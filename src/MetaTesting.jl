module MetaTesting

using Test

export nonpassing_results, fails, errors

"""
    EncasedTestSet(desc, results) <: AbstractTestset

A custom testset that encases all test results within, not letting them out.
It doesn't let anything propagate up to the parent testset
(or to the top-level fallback testset, which throws an error on any non-passing result).
Not passes, not failures, not even errors.


This is useful for being able to observe the testsets results programatically;
without them triggering actual passes/failures/errors.
"""
struct EncasedTestSet <: Test.AbstractTestSet
    description::String
    results::Vector{Any}
end
EncasedTestSet(desc) = EncasedTestSet(desc, [])

Test.record(ts::EncasedTestSet, t) = (push!(ts.results, t); t)

function Test.finish(ts::EncasedTestSet)
    if Test.get_testset_depth() != 0
        # Attach this test set to the parent test set *if* it is also a NonPassingTestset
        # Otherwise don't as we don't want to push the errors and failures further up.
        parent_ts = Test.get_testset()
        parent_ts isa EncasedTestSet && Test.record(parent_ts, ts)
        return ts
    end
    return ts
end

"""
    nonpassing_results(f)

`f` should be a function that takes no argument, and calls some code that used `@test`.
Invoking it via `nonpassing_results(f)` will prevent those `@test` being added to the
current testset, and will return a collection of all nonpassing test results.
"""
function nonpassing_results(f)
    # Specify testset type to hijack system
    ts = @testset EncasedTestSet "nonpassing internal" begin
        f()
    end
    return _extract_nonpasses(ts)
end

"extracts as flat collection of failures from a (potential nested) testset"
_extract_nonpasses(x::Test.Result) = [x]
_extract_nonpasses(x::Test.Pass) = Test.Result[]
_extract_nonpasses(ts::EncasedTestSet) = _extract_nonpasses(ts.results)
function _extract_nonpasses(xs::Vector)
    if isempty(xs)
        return Test.Result[]
    else
        return mapreduce(_extract_nonpasses, vcat, xs)
    end
end

"""
    fails(f)

`f` should be a function that takes no argument, and calls some code that used `@test`.
`fails(f)` returns true if at least 1 `@test` fails.
If a test errors then it will display that error and throw an error of its own.

# Examples

```jldoctest; filter=[r"[0-9\\.]+s", r"Test\\.DefaultTestSet\\(.*\\)"]
using MetaTesting, Test

function test_equal(x, y)
    @test x == y
end

@testset "test_equal tests" begin
    test_equal(1, 1)  # passes
    @test fails() do
        test_equal(1, 2)  # fails
    end
end;

# output

Test Summary:    | Pass  Total  Time
test_equal tests |    2      2  0.0s
Test.DefaultTestSet("test_equal tests", Any[], 2, false, false, true, 1.684442217674312e9, 1.684442217756266e9, false)
```
"""
function fails(f)
    results = nonpassing_results(f)
    did_fail = false
    for result in results
        did_fail |= result isa Test.Fail
        if result isa Test.Error
            # Log a error message, with original backtrace
            # Sadly we can't throw the original exception as it is only stored as a String
            error("Error occurred during `fails`")
        end
    end
    return did_fail
end

"""
    errors(f, msg_pattern="")

Returns true if at least 1 error is recorded into a testset
with a failure matching the given pattern.

`f` should be a function that takes no argument, and calls some code that uses `@testset`.
`msg_pattern` is a regex or a string, that should be contained in the error message.
If nothing is passed then it default to the empty string, which matches any error message.

If a test fails (rather than passing or erroring) then `errors` will throw an error.

# Examples

```jldoctest; filter=[r"[0-9\\.]+s", r"Test\\.DefaultTestSet\\(.*\\)"]
using MetaTesting, Test

function test_approx(x, y)
    @test x ≈ y
end

@testset "test_approx tests" begin
    test_approx(1.0, 1.0)  # passes
    @test errors() do
        test_approx(1.0, (2.0,))  # errors, isapprox not defined for types
    end
end;

# output

Test Summary:     | Pass  Total  Time
test_approx tests |    2      2  0.0s
Test.DefaultTestSet("test_approx tests", Any[], 2, false, false, true, 1.684442215984607e9, 1.68444221725024e9, false)
```
"""
function errors(f, msg_pattern="")
    results = nonpassing_results(f)

    for result in results
        result isa Test.Fail && error("Test actually failed (not errored): \n $result")
        result isa Test.Error && occursin(msg_pattern, result.value) && return true
    end
    return false  # no matching error occured
end

end  # module
