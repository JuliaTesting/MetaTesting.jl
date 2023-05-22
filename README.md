# MetaTesting.jl

[![CI](https://github.com/JuliaTesting/MetaTesting.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaTesting/MetaTesting.jl/actions/workflows/CI.yml)
[![Coverage](https://codecov.io/gh/JuliaTesting/MetaTesting.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaTesting/MetaTesting.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)


[![](https://img.shields.io/badge/docs-main-blue.svg)](https://JuliaTesting.github.io/MetaTesting.jl/dev)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaTesting.github.io/MetaTesting.jl/stable)

MetaTesting is a collection of utilities for testing "testers," functions that run tests.
It is primarily intended as a test dependency.

## Example

First we define a tester:

```julia
using Test

function test_approx(x, y)
    @test x ≈ y
end
```

Then we test it using MetaTesting:

```julia
using MetaTesting

@testset begin
    # test that tester correctly passes
    test_approx(1.0, 1.0)

    # test that tester correctly fails
    @test fails() do
        test_approx(1.0, 2.0)  # args not approximately equal
    end

    # test that tester correctly errors
    @test errors() do
        test_approx(1.0, (2.0,))  # isapprox not defined for this pair of types
    end
end
```
