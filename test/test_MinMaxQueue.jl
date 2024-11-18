@testset "MinMaxQueue Tests" begin
    @testset "Basic Operations" begin
        q = MinMaxQueue{Float64}(10)

        # Test sequential updates
        values = [10.0, 5.0, 8.0, 12.0, 3.0, 7.0, 9.0, 4.0, 6.0, 11.0]
        for (i, val) in enumerate(values)
            update!(q, val, val, i)
            @test get_max(q) == maximum(values[1:i])
            @test get_min(q) == minimum(values[1:i])
        end

        # Test sequential removals
        for i in 1:5
            remove_old!(q, i)
            @test get_max(q) == maximum(values[(i+1):10])
            @test get_min(q) == minimum(values[(i+1):10])
        end
    end

    @testset "Large Window Sliding" begin
        q = MinMaxQueue{Int}(8)

        # Test larger sliding window
        sequence = [1, 5, 2, 8, 3, 9, 4, 7]
        for (i, val) in enumerate(sequence)
            update!(q, val, val, i)
        end
        @test get_max(q) == 9
        @test get_min(q) == 1

        # Slide window and verify correctness
        for i in 1:4
            remove_old!(q, i)
            update!(q, i + 10, i + 10, i + 8)
            expected_window = vcat(sequence[(i+1):8], [i + 10])
            @test get_max(q) == maximum(expected_window)
            @test get_min(q) == minimum(expected_window)
        end
    end

    @testset "Different High/Low Values" begin
        q = MinMaxQueue{Float64}(5)

        # Test multiple high/low combinations
        highs = [10.0, 15.0, 12.0, 18.0, 14.0]
        lows = [5.0, 3.0, 8.0, 4.0, 6.0]

        for i in 1:5
            update!(q, highs[i], lows[i], i)
            @test get_max(q) == maximum(highs[1:i])
            @test get_min(q) == minimum(lows[1:i])
        end

        # Test removal impact on high/low values
        for i in 1:3
            remove_old!(q, i)
            @test get_max(q) == maximum(highs[(i+1):5])
            @test get_min(q) == minimum(lows[(i+1):5])
        end
    end

    @testset "Edge Cases and Error Handling" begin
        q = MinMaxQueue{Int}(5)

        # Empty queue behavior
        @test_throws BoundsError get_max(q)
        @test_throws BoundsError get_min(q)

        # Single element
        update!(q, 5, 5, 1)
        @test get_max(q) == 5
        @test get_min(q) == 5

        # Duplicate values
        for i in 2:5
            update!(q, 5, 5, i)
        end
        @test get_max(q) == 5
        @test get_min(q) == 5

        # Remove all elements sequentially
        for i in 1:5
            remove_old!(q, i)
            if i < 5
                @test get_max(q) == 5
                @test get_min(q) == 5
            else
                @test_throws BoundsError get_max(q)
                @test_throws BoundsError get_min(q)
            end
        end
    end

    @testset "Stress Test" begin
        queue_size = 100
        update_size = 1000
        q = MinMaxQueue{Int}(queue_size)

        # Large number of operations
        values = rand(1:1000, queue_size)
        for (i, val) in enumerate(values)
            update!(q, val, val, i)
            @test get_max(q) == maximum(values[1:i])
            @test get_min(q) == minimum(values[1:i])
        end

        # Sliding window over large dataset
        append!(values, rand(1:1000, update_size))
        for i in 1:update_size
            remove_old!(q, i)
            update!(q, values[i + queue_size], values[i + queue_size], i + queue_size)
            current_window = view(values, (i+1):(queue_size + i))
            @test get_max(q) == maximum(current_window)
            @test get_min(q) == minimum(current_window)
        end
    end

    @testset "Monotonicity Property" begin
        q = MinMaxQueue{Float64}(10)

        # Test monotonically increasing sequence
        for i in 1:10
            update!(q, Float64(i), Float64(i), i)
            @test get_max(q) == i
            @test get_min(q) == 1.0
        end

        # Test monotonically decreasing sequence
        q = MinMaxQueue{Float64}(10)
        for i in 1:10
            update!(q, 11.0 - i, 11.0 - i, i)
            @test get_max(q) == 10.0
            @test get_min(q) == 11.0 - i
        end
    end
end