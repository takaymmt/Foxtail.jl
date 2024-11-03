@testset "CircularBuffer" begin

    @testset "Core Functionality" begin
        cb = CircBuff{Int}(5)
        @testset "When empty" begin
            @test length(cb) == 0
            @test capacity(cb) == 5
            @test_throws BoundsError first(cb)
            @test_throws BoundsError last(cb)
            @test isempty(cb) == true
            @test isfull(cb) == false
            @test eltype(cb) == Int
            @test eltype(typeof(cb)) == Int
        end

        @testset "With 1 element" begin
            push!(cb, 1)
            @test length(cb) == 1
            @test capacity(cb) == 5
            @test isfull(cb) == false
            @test first(cb) == last(cb)
        end

        @testset "Appending small element" begin
            append!(cb, 2:4)
            @test length(cb) == 4
            @test isfull(cb) == false
            @test value(cb) == Int[1,2,3,4]
        end

        @testset "Appending many elements" begin
            append!(cb, 5:8)
            @test length(cb) == capacity(cb)
            @test size(cb) == (length(cb),)
            @test isempty(cb) == false
            @test isfull(cb) == true
            @test value(cb) == Int[4,5,6,7,8]
        end

        @testset "getindex" begin
            @test cb[1] == 4
            @test cb[2] == 5
            @test cb[3] == 6
            @test cb[4] == 7
            @test cb[5] == 8
            @test cb[6] == 4
            @test cb[3:6] == [6,7,8,4]
            @test cb[3:4] == Int[6,7]
            @test cb[[1,5]] == Int[4,8]
            @test first(cb) == 4
            @test last(cb) == 8
        end

        @testset "setindex" begin
            cb[3] = 999
            @test value(cb) == Int[4,5,999,7,8]
        end
    end

    @testset "other constructors" begin
        @testset "internal constructor" begin
            @test_throws ArgumentError CircBuff{Int64}(-1)
            @test_throws ArgumentError CircBuff{Int64}(0,Vector{Int64}(undef,5))
        end
        @testset "capacity only" begin
            cb = CircBuff(10)
            @test length(cb) == 0
            @test typeof(cb) <: CircBuff{Float64}
        end
        @testset "from vec inferred type with capacity" begin
            cb = CircBuff(10, 1:5)
            @test length(cb) == 5
            @test typeof(cb) == CircBuff{Int}
        end
        @testset "from vec given type with capacity" begin
            cb = CircBuff{Float64}(10, 1:5)
            @test length(cb) == 5
            @test typeof(cb) == CircBuff{Float64}
            @test value(cb) == [1.0,2.0,3.0,4.0,5.0]
        end
        @testset "inferred capacity given type" begin
            cb = CircBuff{Float64}(1:5)
            @test length(cb) == 5
            @test typeof(cb) == CircBuff{Float64}
            @test value(cb) == [1.0,2.0,3.0,4.0,5.0]
            @test capacity(cb) == 5
        end
        @testset "inferred capacity inferred type" begin
            cb = CircBuff(1:5)
            @test length(cb) == 5
            @test typeof(cb) == CircBuff{Int}
            @test value(cb) == [1,2,3,4,5]
            @test capacity(cb) == 5
        end

    end

    @testset "popfirst 1" begin
        cb = CircBuff{Int}(5)
        pushfirst!(cb, 1)
        @test value(cb) == [1]
        pushfirst!(cb, 2)
        @test value(cb) == [2, 1]
    end

    @testset "pushfirst 2" begin
        cb = CircBuff{Int}(5)  # New, empty one for full test coverage
        for i in -5:5
            pushfirst!(cb, i)
        end
        arr = value(cb)
        @test arr == Int[5, 4, 3, 2, 1]
        for (idx, n) in enumerate(5:1)
            @test arr[idx] == n
        end
    end

    @testset "map and pop" begin
        cb = CircBuff{Int}(5)
        map(x -> pushfirst!(cb, x), 1:8)
        pop!(cb)
        pushfirst!(cb, 9)
        @test length(cb.buffer) == cb.capacity
        arr = value(cb)
        @test arr == Int[9, 8, 7, 6, 5]
    end

    @testset "empty!" begin
        cb = CircBuff{Int}(5)
        push!(cb, 13)
        empty!(cb)
        @test length(cb) == 0
        pushfirst!(cb, 24)
        a = pop!(cb)
        @test a == 24
        push!(cb, [1,2,3,])
        empty!(cb)
        @test length(cb) == 0
    end

    @testset "pop!" begin
        cb = CircBuff{Int}(5)
        for i in 0:5    # one extra to force wraparound
            push!(cb, i)
        end
        for j in 5:-1:1
            @test pop!(cb) == j
            @test value(cb) == collect(1:j-1)
        end
        @test isempty(cb)
        @test_throws ArgumentError pop!(cb)
    end

    @testset "popfirst!" begin
        cb = CircBuff{Int}(5)
        for i in 0:5    # one extra to force wraparound
            push!(cb, i)
        end
        for j in 1:5
            @test popfirst!(cb) == j
            @test value(cb) == collect(j+1:5)
        end
        @test isempty(cb)
        @test_throws ArgumentError popfirst!(cb)
    end

    @testset "fill!" begin
        @testset "fill an empty buffer" begin
            cb = CircBuff{Int}(3)
            fill!(cb, 42)
            @test value(cb) == [42, 42, 42]
        end
        @testset "fill a non empty buffer" begin
            cb = CircBuff{Int}(3)
            push!(cb, 21)
            fill!(cb, 42)
            @test value(cb) == [21, 42, 42]
        end
    end

    @testset "merge_in!" begin
        @testset "merge a small vector" begin
            cb = CircBuff{Int}(5)
            push!(cb, 21)
            merge_in!(cb, [42,84])
            @test value(cb) == [21,42,84]
        end
        @testset "merge a large vector" begin
            cb = CircBuff{Int}(5)
            push!(cb, 21)
            merge_in!(cb, [42,43,44,45,46,47,48])
            @test value(cb) == [21,42,43,44,45]
        end
    end

    @testset "Type converting check" begin
        cb = CircBuff{Int}(5)
        @test_throws InexactError push!(cb, 1.5)
        @test_throws InexactError pushfirst!(cb, 1.5)
        @test_throws InexactError fill!(cb, 1.5)
        @test_throws InexactError append!(cb, [1.0, 1.5, 2.0])
        @test_throws InexactError merge_in!(cb, [2.0, 2.5, 3.0])
        @test length(cb) == 0
        push!(cb, 1.0)
        @test length(cb) == 1
        pushfirst!(cb, 2.0)
        @test length(cb) == 2
        fill!(cb, 3.0)
        @test value(cb) == [2,1,3,3,3]
        empty!(cb)
        merge_in!(cb, 4.0:10.0)
        @test value(cb) == [4,5,6,7,8]
        append!(cb, 4.0:10.0)
        @test value(cb) == [6,7,8,9,10]
        cb[3] = 42.0
        @test value(cb) == [6,7,42,9,10]
    end
end