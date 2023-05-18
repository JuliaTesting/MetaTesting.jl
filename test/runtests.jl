using MetaTesting
using Test

@testset "MetaTesting.jl" begin
    @testset "nonpassing_results" begin
        @testset "No Tests" begin
            fails = nonpassing_results(() -> nothing)
            @test length(fails) === 0
        end

        @testset "No Failures" begin
            fails = nonpassing_results(() -> @test true)
            @test length(fails) === 0
        end

        @testset "Single Test" begin
            fails = nonpassing_results(() -> @test false)
            @test length(fails) === 1
            # Julia 1.6 return a `String`, not an `Expr`.
            # Always calling  `string` on it gives gives consistency regardless of version.
            # https://github.com/JuliaLang/julia/pull/37809
            @test string(fails[1].orig_expr) == string(false)
        end

        @testset "Single Testset" begin
            fails = nonpassing_results() do
                @testset "inner" begin
                    @test false == true
                    @test true == false
                end
            end
            @test length(fails) === 2

            # Julia 1.6 return a `String`, not an `Expr`.
            # Always calling  `string` on it gives gives consistency regardless of version.
            # https://github.com/JuliaLang/julia/pull/37809
            @test string(fails[1].orig_expr) == string(:(false == true))
            @test string(fails[2].orig_expr) == string(:(true == false))
        end

        @testset "Single Error" begin
            bads = nonpassing_results(() -> error("noo"))
            @test length(bads) === 1
            @test bads[1] isa Test.Error
        end

        @testset "Single Test Erroring" begin
            bads = nonpassing_results(() -> @test error("nooo"))
            @test length(bads) === 1
            @test bads[1] isa Test.Error
        end

        @testset "Single Testset Erroring" begin
            bads = nonpassing_results() do
                @testset "inner" begin
                    error("noo")
                end
            end
            @test length(bads) === 1
            @test bads[1] isa Test.Error
        end
    end

    @testset "fails" begin
        @test !fails(() -> @test true)
        @test fails(() -> @test false)
        @test !fails(() -> @test_broken false)

        @test fails() do
            @testset "eg" begin
                @test true
                @test false
                @test true
            end
        end

        @test_throws ErrorException fails(() -> @test error("Bad"))
    end

    @testset "errors" begin
        @test !errors(() -> @test true)
        @test errors(() -> error("nooo"))
        @test errors(() -> error("nooo"), "noo")
        @test !errors(() -> error("nooo"), "ok")

        @test errors() do
            @testset "eg" begin
                @test true
                error("nooo")
                @test true
            end
        end

        @test_throws ErrorException errors(() -> @test false)
    end
end
