using Test
using Foxtail
using TSFrames
using CSV

aapl = CSV.read(joinpath(@__DIR__, "aapl.csv"), TSFrame)
data_ts = aapl[end-100:end]

@testset "Indicators MIMO" begin
    # Fixed realistic financial data replacing rand() arrays
    # 100-row arrays with plausible High/Low/Close values

    _high_col = [
        52.3, 53.1, 51.8, 54.2, 55.0, 53.6, 56.1, 57.3, 55.5, 58.0,
        59.2, 57.0, 60.3, 61.5, 59.1, 62.4, 63.6, 61.2, 64.5, 65.7,
        63.3, 66.6, 67.8, 65.4, 68.7, 69.9, 67.5, 70.8, 71.9, 69.6,
        72.7, 73.5, 71.3, 74.8, 75.6, 73.2, 76.9, 77.7, 75.5, 78.8,
        79.6, 77.4, 80.5, 81.3, 79.1, 82.4, 83.2, 81.0, 84.3, 85.1,
        82.9, 86.2, 87.0, 84.8, 88.1, 88.9, 86.7, 90.0, 90.8, 88.6,
        91.7, 92.5, 90.3, 93.6, 94.4, 92.2, 95.5, 96.3, 94.1, 97.4,
        98.2, 96.0, 99.3, 100.1, 97.9, 101.2, 102.0, 99.8, 103.1, 103.9,
        101.7, 104.8, 105.6, 103.4, 106.7, 107.5, 105.3, 108.6, 109.4, 107.2,
        110.5, 111.3, 109.1, 112.4, 113.2, 111.0, 114.3, 115.1, 112.9, 116.2
    ]
    _low_col = [
        49.1, 49.8, 48.5, 51.0, 51.7, 50.3, 52.8, 53.5, 52.2, 54.7,
        55.4, 53.7, 56.5, 57.7, 55.3, 58.6, 59.8, 57.4, 60.7, 61.9,
        59.5, 62.8, 64.0, 61.6, 65.0, 66.1, 63.7, 67.0, 68.2, 65.8,
        69.0, 69.7, 67.5, 71.0, 71.8, 69.4, 73.2, 73.9, 71.7, 75.0,
        75.8, 73.6, 76.7, 77.5, 75.3, 78.6, 79.4, 77.2, 80.5, 81.3,
        79.1, 82.4, 83.2, 81.0, 84.3, 85.1, 82.9, 86.2, 87.0, 84.8,
        87.9, 88.7, 86.5, 89.8, 90.6, 88.4, 91.7, 92.5, 90.3, 93.6,
        94.4, 92.2, 95.5, 96.3, 94.1, 97.4, 98.2, 96.0, 99.3, 100.1,
        97.9, 101.0, 101.8, 99.6, 103.0, 103.7, 101.5, 104.8, 105.6, 103.4,
        106.7, 107.5, 105.3, 108.6, 109.4, 107.2, 110.5, 111.3, 109.1, 112.4
    ]
    _close_col = [
        50.7, 51.5, 50.1, 52.6, 53.4, 52.0, 54.5, 55.4, 53.8, 56.3,
        57.3, 55.3, 58.4, 59.6, 57.2, 60.5, 61.7, 59.3, 62.6, 63.8,
        61.4, 64.7, 65.9, 63.5, 66.8, 68.0, 65.6, 68.9, 70.1, 67.7,
        70.8, 71.6, 69.4, 72.9, 73.7, 71.3, 75.0, 75.8, 73.6, 76.9,
        77.7, 75.5, 78.6, 79.4, 77.2, 80.5, 81.3, 79.1, 82.4, 83.2,
        81.0, 84.3, 85.1, 82.9, 86.2, 87.0, 84.8, 88.1, 88.9, 86.7,
        89.8, 90.6, 88.4, 91.7, 92.5, 90.3, 93.6, 94.4, 92.2, 95.5,
        96.3, 94.1, 97.4, 98.2, 96.0, 99.3, 100.1, 97.9, 101.2, 102.0,
        99.8, 102.9, 103.7, 101.5, 104.8, 105.6, 103.4, 106.7, 107.5, 105.3,
        108.6, 109.4, 107.2, 110.5, 111.3, 109.1, 112.4, 113.2, 111.0, 114.3
    ]

    vec2 = hcat(_high_col, _low_col)
    vec3 = hcat(_high_col, _low_col, _close_col)

    @testset "Stochastic" begin
        @test Stoch(vec3) isa Matrix{Float64}
        res = Stoch(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "Stoch_K"
        @test names(res)[2] == "Stoch_D"
        @test Stoch(data_ts; n=25, k_smooth=4, d_smooth=5) isa TSFrame
        @test Stoch(data_ts; ma_type=:EMA) isa TSFrame
        @test Stoch(data_ts; ma_type=:SMMA) isa TSFrame

        # No NaN/Inf in output
        stoch_result = Stoch(vec3)
        @test !any(isnan, stoch_result)
        @test !any(isinf, stoch_result)

        # Numerical validation
        # Stochastic with known data: %K = 100*(close-lowest)/(highest-lowest)
        stoch_data = Float64[10 8 9; 11 9 10; 12 10 11; 11 9 10; 13 11 12;
                             14 12 13; 13 11 12; 15 13 14; 16 14 15; 15 13 14]
        s = Stoch(stoch_data; n=3, k_smooth=2, d_smooth=2)
        @test s[1,1] ≈ 50.0 atol=1e-8                        # first raw K
        @test s[end,1] ≈ 56.66666666666667 atol=1e-6         # K at end
        @test s[end,2] ≈ 67.08333333333334 atol=1e-6         # D at end

        # K and D should be bounded roughly in [0, 100]
        for i in 1:10
            @test -1.0 <= s[i,1] <= 101.0
            @test -1.0 <= s[i,2] <= 101.0
        end
    end

    @testset "Williams R" begin
        @test WR(vec3) isa Matrix{Float64}
        res = WR(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "WR_raw"
        @test names(res)[2] == "WR_EMA"
        @test WR(data_ts; n=25) isa TSFrame

        # No NaN/Inf in output
        wr_result = WR(vec3)
        @test !any(isnan, wr_result)
        @test !any(isinf, wr_result)

        # Numerical validation
        # WR = -100 * (highest - close) / (highest - lowest)
        wr_data = Float64[10 8 9; 11 9 10; 12 10 11; 11 9 10; 13 11 12;
                          14 12 13; 13 11 12; 15 13 14; 16 14 15; 15 13 14]
        r = WR(wr_data; n=3)
        @test r[1,1] ≈ -50.0 atol=1e-8                       # (10-9)/(10-8) = 0.5 -> -50
        @test r[end,1] ≈ -66.66666666666667 atol=1e-6
        @test r[end,2] ≈ -52.694541821199344 atol=1e-6       # EMA smoothed

        # WR raw should be in [-100, 0] range
        for i in 1:10
            @test -100.0 <= r[i,1] <= 0.0 + 1e-10
        end
    end

    @testset "DonchianChannel" begin
        @test DonchianChannel(vec3) isa Matrix{Float64}
        res = DonchianChannel(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "DonchianChannel_Upper"
        @test names(res)[2] == "DonchianChannel_Lower"
        @test names(res)[3] == "DonchianChannel_Middle"
        @test DonchianChannel(data_ts; n=25) isa TSFrame

        # No NaN/Inf in output
        dc_result = DonchianChannel(vec3)
        @test !any(isnan, dc_result)
        @test !any(isinf, dc_result)

        # Numerical validation
        # DonchianChannel n=3 with linear data
        # High=Low=Close for simplicity (all same column)
        dc_data = Float64[1 1 1; 2 2 2; 3 3 3; 4 4 4; 5 5 5;
                          6 6 6; 7 7 7; 8 8 8; 9 9 9; 10 10 10]
        d = DonchianChannel(dc_data; n=3)
        # Upper[3] = max(1,2,3) = 3.0, Lower[3] = min(1,2,3) = 1.0, Middle = 2.0
        @test d[3,1] ≈ 3.0 atol=1e-10
        @test d[3,2] ≈ 1.0 atol=1e-10
        @test d[3,3] ≈ 2.0 atol=1e-10
        # Upper[10] = max(8,9,10)=10.0, Lower[10] = min(8,9,10)=8.0, Middle=9.0
        @test d[10,1] ≈ 10.0 atol=1e-10
        @test d[10,2] ≈ 8.0 atol=1e-10
        @test d[10,3] ≈ 9.0 atol=1e-10

        # With different High/Low: High increasing by 2, Low increasing by 1
        dc_data2 = Float64[10 5 7; 12 6 8; 14 7 9; 16 8 10; 18 9 11]
        d2 = DonchianChannel(dc_data2; n=3)
        # At i=3: Upper=max(10,12,14)=14, Lower=min(5,6,7)=5, Middle=9.5
        @test d2[3,1] ≈ 14.0 atol=1e-10
        @test d2[3,2] ≈ 5.0 atol=1e-10
        @test d2[3,3] ≈ 9.5 atol=1e-10
        # At i=5: Upper=max(14,16,18)=18, Lower=min(7,8,9)=7, Middle=12.5
        @test d2[5,1] ≈ 18.0 atol=1e-10
        @test d2[5,2] ≈ 7.0 atol=1e-10
        @test d2[5,3] ≈ 12.5 atol=1e-10

        # Middle should always be between Upper and Lower
        for i in 1:10
            @test d[i,2] <= d[i,3] <= d[i,1]
        end

        # Input validation
        @test_throws ArgumentError DonchianChannel(rand(10, 2))  # wrong column count
        @test_throws ArgumentError DonchianChannel(rand(10, 3); n=0)  # period must be positive
        @test_throws ArgumentError DonchianChannel(rand(3, 3); n=5)  # length < period
    end

    @testset "KeltnerChannel" begin
        @test KeltnerChannel(vec3) isa Matrix{Float64}
        res = KeltnerChannel(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "KeltnerChannel_Middle"
        @test names(res)[2] == "KeltnerChannel_Upper"
        @test names(res)[3] == "KeltnerChannel_Lower"
        @test KeltnerChannel(data_ts; n=25) isa TSFrame
        @test KeltnerChannel(data_ts; n=20, mult=1.5) isa TSFrame

        # No NaN/Inf in output
        kc_result = KeltnerChannel(vec3)
        @test !any(isnan, kc_result)
        @test !any(isinf, kc_result)

        # Numerical validation
        # KeltnerChannel: Middle=EMA(Close), Upper=Middle+mult*ATR, Lower=Middle-mult*ATR
        kc_data = Float64[10 8 9; 11 9 10; 12 10 11; 13 11 12; 14 12 13;
                          15 13 14; 16 14 15; 17 15 16; 18 16 17; 19 17 18]
        kc = KeltnerChannel(kc_data; n=3, mult=2.0)
        # Middle should equal EMA(close, n=3)
        ema_ref = EMA([9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0]; n=3)
        atr_ref = ATR(kc_data; n=3)
        for i in 1:10
            @test kc[i,1] ≈ ema_ref[i] atol=1e-10              # Middle = EMA
            @test kc[i,2] ≈ ema_ref[i] + 2.0 * atr_ref[i] atol=1e-10  # Upper
            @test kc[i,3] ≈ ema_ref[i] - 2.0 * atr_ref[i] atol=1e-10  # Lower
        end

        # Upper should always be >= Middle >= Lower
        for i in 1:10
            @test kc[i,3] <= kc[i,1] <= kc[i,2]
        end

        # Input validation
        @test_throws ArgumentError KeltnerChannel(rand(10, 2))  # wrong column count
        @test_throws ArgumentError KeltnerChannel(rand(10, 3); n=0)  # period must be positive
    end

    @testset "Supertrend" begin
        @test Supertrend(vec3) isa Matrix{Float64}
        res = Supertrend(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "Supertrend_Value"
        @test names(res)[2] == "Supertrend_Direction"
        @test Supertrend(data_ts; n=10) isa TSFrame
        @test Supertrend(data_ts; n=10, mult=2.0) isa TSFrame

        # Direction values should be only 1.0 or -1.0
        st = Supertrend(vec3)
        @test all(d -> d == 1.0 || d == -1.0, st[:, 2])

        # No NaN/Inf in output
        @test !any(isnan, st)
        @test !any(isinf, st)

        # Value should be positive for well-formed positive prices with small ATR
        # Use tight-range prices (small H-L spread) to ensure TP - mult*ATR > 0
        pos_prices = zeros(50, 3)
        for i in 1:50
            base = 100.0 + Float64(i)
            pos_prices[i, 1] = base + 1.0   # High
            pos_prices[i, 2] = base - 1.0   # Low
            pos_prices[i, 3] = base          # Close
        end
        st_pos = Supertrend(pos_prices; n=7, mult=1.0)
        @test all(v -> v > 0.0, st_pos[:, 1])

        # Monotonically rising prices should eventually give uptrend (Direction=1.0)
        rising = hcat([10.0+i for i in 1:30], [8.0+i for i in 1:30], [9.0+i for i in 1:30])
        st_rise = Supertrend(rising; n=7, mult=1.0)
        @test st_rise[end, 2] == 1.0  # uptrend

        # Monotonically falling prices should eventually give downtrend (Direction=-1.0)
        falling = hcat([100.0-i for i in 1:30], [98.0-i for i in 1:30], [99.0-i for i in 1:30])
        st_fall = Supertrend(falling; n=7, mult=1.0)
        @test st_fall[end, 2] == -1.0  # downtrend

        # Numerical validation with known data
        st_data = Float64[10 8 9; 11 9 10; 12 10 11; 13 11 12; 14 12 13;
                          15 13 14; 16 14 15; 17 15 16; 18 16 17; 19 17 18]
        st_num = Supertrend(st_data; n=3, mult=2.0)
        # With steadily rising prices, direction should be uptrend (1.0)
        @test st_num[end, 2] == 1.0
        # Value should equal the lower band (active band during uptrend)
        @test st_num[end, 1] > 0.0

        # AAPL smoke test
        st_aapl = Supertrend(data_ts)
        @test st_aapl isa TSFrame
        @test size(st_aapl)[1] == size(data_ts)[1]
        aapl_mat = Supertrend(data_ts[:, [:High, :Low, :Close]] |> Matrix)
        @test all(d -> d == 1.0 || d == -1.0, aapl_mat[:, 2])

        # Input validation
        @test_throws ArgumentError Supertrend(rand(10, 2))  # wrong column count
        @test_throws ArgumentError Supertrend(rand(10, 3); n=0)  # period must be positive
        @test_throws ArgumentError Supertrend(rand(10, 3); mult=-1.0)  # multiplier must be positive
    end

    @testset "DMI" begin
        @test DMI(vec3) isa Matrix{Float64}
        res = DMI(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "DMI_DIPlus"
        @test names(res)[2] == "DMI_DIMinus"
        @test names(res)[3] == "DMI_ADX"
        @test DMI(data_ts; n=20) isa TSFrame

        # All values should be non-negative
        dmi = DMI(vec3)
        @test all(v -> v >= 0.0, dmi[:, 1])  # DIPlus >= 0
        @test all(v -> v >= 0.0, dmi[:, 2])  # DIMinus >= 0
        @test all(v -> v >= 0.0, dmi[:, 3])  # ADX >= 0

        # ADX should be bounded in [0, 100]
        @test all(v -> v >= 0.0 && v <= 100.0, dmi[:, 3])

        # No NaN/Inf in output
        @test !any(isnan, dmi)
        @test !any(isinf, dmi)

        # Numerical validation with known data
        dmi_data = Float64[10 8 9; 11 9 10; 12 10 11; 13 11 12; 14 12 13;
                           15 13 14; 16 14 15; 17 15 16; 18 16 17; 19 17 18;
                           20 18 19; 21 19 20; 22 20 21; 23 21 22; 24 22 23;
                           25 23 24; 26 24 25; 27 25 26; 28 26 27; 29 27 28]
        dmi_num = DMI(dmi_data; n=5)
        # With steady uptrend, DIPlus should be > DIMinus
        @test dmi_num[end, 1] > dmi_num[end, 2]
        # ADX should be in [0, 100]
        for i in 1:20
            @test 0.0 <= dmi_num[i, 3] <= 100.0
        end

        # With steady downtrend, DIMinus should dominate
        dmi_down = hcat([100.0-i for i in 1:20], [98.0-i for i in 1:20], [99.0-i for i in 1:20])
        dmi_dn = DMI(dmi_down; n=5)
        @test dmi_dn[end, 2] > dmi_dn[end, 1]  # DIMinus > DIPlus

        # AAPL smoke test
        dmi_aapl = DMI(data_ts)
        @test dmi_aapl isa TSFrame
        @test size(dmi_aapl)[1] == size(data_ts)[1]
        aapl_dmi_mat = DMI(data_ts[:, [:High, :Low, :Close]] |> Matrix)
        @test all(v -> v >= 0.0 && v <= 100.0, aapl_dmi_mat[:, 3])  # ADX bounded

        # Input validation
        @test_throws ArgumentError DMI(rand(10, 2))  # wrong column count
        @test_throws ArgumentError DMI(rand(10, 3); n=0)  # period must be positive
    end

    @testset "Aroon" begin
        # Type checks
        @test Aroon(vec2) isa Matrix{Float64}
        res = Aroon(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "Aroon_Up"
        @test names(res)[2] == "Aroon_Down"
        @test names(res)[3] == "Aroon_Oscillator"
        @test Aroon(data_ts; n=10) isa TSFrame

        # Range checks on fixed data
        aroon_fixed = Aroon(vec2)
        @test all(v -> 0.0 <= v <= 100.0, aroon_fixed[:, 1])   # Up in [0, 100]
        @test all(v -> 0.0 <= v <= 100.0, aroon_fixed[:, 2])   # Down in [0, 100]
        @test all(v -> -100.0 <= v <= 100.0, aroon_fixed[:, 3]) # Oscillator in [-100, 100]

        # No NaN/Inf in output
        @test !any(isnan, aroon_fixed)
        @test !any(isinf, aroon_fixed)

        # Oscillator = Up - Down
        @test aroon_fixed[:, 3] ≈ aroon_fixed[:, 1] - aroon_fixed[:, 2] atol=1e-10

        # Monotonically rising High: AroonUp should be 100.0 (new high each bar)
        rising_high = hcat(collect(1.0:30.0), ones(30) * 50.0)
        aroon_rise = Aroon(rising_high; n=10)
        @test all(v -> v ≈ 100.0, aroon_rise[:, 1])

        # Monotonically falling Low: AroonDown should be 100.0 (new low each bar)
        falling_low = hcat(ones(30) * 50.0, collect(30.0:-1.0:1.0))
        aroon_fall = Aroon(falling_low; n=10)
        @test all(v -> v ≈ 100.0, aroon_fall[:, 2])

        # Numerical validation with small data (n=3)
        # Highs monotonically rising, Lows monotonically falling
        highs = [1.0, 2.0, 3.0, 4.0, 5.0]
        lows  = [5.0, 4.0, 3.0, 2.0, 1.0]
        prices_small = [highs lows]
        r = Aroon(prices_small; n=3)

        # Bar 4 (window [2,3,4]): high at bar 4 (most recent), low at bar 4 (most recent)
        @test r[4, 1] ≈ 100.0 atol=1e-10  # AroonUp: high at current bar
        @test r[4, 2] ≈ 100.0 atol=1e-10  # AroonDown: low at current bar

        # Bar 1: only 1 bar in window, both high and low are at bar 1
        @test r[1, 1] ≈ 100.0 atol=1e-10  # bars_since_high = 0
        @test r[1, 2] ≈ 100.0 atol=1e-10  # bars_since_low = 0

        # Reverse: highs falling, lows rising -> high at oldest bar in window
        highs2 = [5.0, 4.0, 3.0, 2.0, 1.0]
        lows2  = [1.0, 2.0, 3.0, 4.0, 5.0]
        prices2 = [highs2 lows2]
        r2 = Aroon(prices2; n=3)

        # Bar 5 (window [2,3,4,5]): high at bar 2 (oldest), low at bar 2 (oldest)
        @test r2[5, 1] ≈ 0.0 atol=1e-10   # AroonUp: 100*(3-(5-2))/3 = 0
        @test r2[5, 2] ≈ 0.0 atol=1e-10   # AroonDown: 100*(3-(5-2))/3 = 0
        @test r2[5, 3] ≈ 0.0 atol=1e-10   # Oscillator = 0

        # Bar 4 (window [1,2,3,4]): high at bar 1, low at bar 1
        @test r2[4, 1] ≈ 100.0 * (3 - (4 - 1)) / 3 atol=1e-10  # = 0.0
        @test r2[4, 2] ≈ 100.0 * (3 - (4 - 1)) / 3 atol=1e-10  # = 0.0

        # Specific known values: mixed data
        # Highs: [3, 7, 2, 5, 4], Lows: [1, 3, 0, 2, 1]
        highs3 = [3.0, 7.0, 2.0, 5.0, 4.0]
        lows3  = [1.0, 3.0, 0.0, 2.0, 1.0]
        prices3 = [highs3 lows3]
        r3 = Aroon(prices3; n=3)

        # Bar 5 (window [2,3,4,5]): highest high=7 at idx 2, lowest low=0 at idx 3
        @test r3[5, 1] ≈ 100.0 * (3 - (5 - 2)) / 3 atol=1e-10  # = 0.0
        @test r3[5, 2] ≈ 100.0 * (3 - (5 - 3)) / 3 atol=1e-10  # = 33.333...
        @test r3[5, 3] ≈ r3[5, 1] - r3[5, 2] atol=1e-10

        # Input validation
        @test_throws ArgumentError Aroon(rand(10, 3))  # wrong column count
        @test_throws ArgumentError Aroon(rand(10, 2); n=0)  # invalid period

        # AAPL smoke test
        aroon_aapl = Aroon(data_ts)
        @test aroon_aapl isa TSFrame
        @test size(aroon_aapl)[1] == size(data_ts)[1]
        aapl_aroon_mat = Aroon(data_ts[:, [:High, :Low]] |> Matrix)
        @test all(v -> 0.0 <= v <= 100.0, aapl_aroon_mat[:, 1])
        @test all(v -> 0.0 <= v <= 100.0, aapl_aroon_mat[:, 2])
        @test all(v -> -100.0 <= v <= 100.0, aapl_aroon_mat[:, 3])
    end

    @testset "SqueezeMomentum" begin
        # Type checks: Matrix input returns Matrix output
        @test SqueezeMomentum(vec3) isa Matrix{Float64}
        sm = SqueezeMomentum(vec3)
        @test size(sm, 2) == 2  # [Histogram, Squeeze]

        # TSFrame input returns TSFrame output
        res = SqueezeMomentum(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "SqueezeMomentum_Histogram"
        @test names(res)[2] == "SqueezeMomentum_Squeeze"

        # Custom parameters
        @test SqueezeMomentum(data_ts; n=10) isa TSFrame
        @test SqueezeMomentum(data_ts; n=20, bb_mult=2.0, kc_mult=1.5) isa TSFrame

        # Squeeze column values are 0.0 or 1.0 only
        sm_fixed = SqueezeMomentum(vec3)
        @test all(v -> v == 0.0 || v == 1.0, sm_fixed[:, 2])

        # All histogram values should be finite
        @test all(isfinite, sm_fixed[:, 1])

        # No NaN/Inf in output
        @test !any(isnan, sm_fixed)
        @test !any(isinf, sm_fixed)

        # Low-volatility period (constant prices with tiny noise):
        # BB very narrow -> inside KC -> squeeze should be ON (1.0)
        low_vol = zeros(50, 3)
        for i in 1:50
            base = 100.0
            low_vol[i, 1] = base + 0.01  # High
            low_vol[i, 2] = base - 0.01  # Low
            low_vol[i, 3] = base          # Close
        end
        sm_low = SqueezeMomentum(low_vol; n=20, bb_mult=2.0, kc_mult=1.5)
        # After warmup period, squeeze should be ON
        @test all(v -> v == 1.0, sm_low[25:end, 2])

        # High-volatility period (large close swings, small H-L spread):
        # BB wider than KC -> squeeze should be OFF (0.0)
        # Close varies wildly but High-Low spread is tiny, so ATR is small
        # while BB (based on close std) is wide
        high_vol = zeros(50, 3)
        for i in 1:50
            swing = 20.0 * sin(i * 0.5)
            high_vol[i, 1] = 100.0 + swing + 0.1  # High = Close + tiny offset
            high_vol[i, 2] = 100.0 + swing - 0.1  # Low  = Close - tiny offset
            high_vol[i, 3] = 100.0 + swing         # Close swings widely
        end
        sm_high = SqueezeMomentum(high_vol; n=20, bb_mult=2.0, kc_mult=1.5)
        # After warmup, at least some bars should have squeeze OFF
        @test any(v -> v == 0.0, sm_high[25:end, 2])

        # Numerical validation: linear regression helper correctness
        # For a perfectly linear series [1,2,3,4,5], linreg should return 5.0
        # We test this indirectly: with steadily rising prices,
        # momentum histogram should be positive
        rising = zeros(40, 3)
        for i in 1:40
            rising[i, 1] = 50.0 + Float64(i) + 1.0  # High
            rising[i, 2] = 50.0 + Float64(i) - 1.0  # Low
            rising[i, 3] = 50.0 + Float64(i)         # Close
        end
        sm_rise = SqueezeMomentum(rising; n=10, bb_mult=2.0, kc_mult=1.5)
        # After warmup, histogram should be positive (upward momentum)
        @test all(v -> v > 0.0, sm_rise[20:end, 1])

        # Steadily falling prices: histogram should be negative
        falling = zeros(40, 3)
        for i in 1:40
            falling[i, 1] = 150.0 - Float64(i) + 1.0  # High
            falling[i, 2] = 150.0 - Float64(i) - 1.0  # Low
            falling[i, 3] = 150.0 - Float64(i)         # Close
        end
        sm_fall = SqueezeMomentum(falling; n=10, bb_mult=2.0, kc_mult=1.5)
        # After warmup, histogram should be negative (downward momentum)
        @test all(v -> v < 0.0, sm_fall[20:end, 1])

        # Input validation
        @test_throws ArgumentError SqueezeMomentum(rand(10, 2))  # wrong column count

        # AAPL smoke test
        sm_aapl = SqueezeMomentum(data_ts)
        @test sm_aapl isa TSFrame
        @test size(sm_aapl)[1] == size(data_ts)[1]
        aapl_sm_mat = SqueezeMomentum(data_ts[:, [:High, :Low, :Close]] |> Matrix)
        @test all(v -> v == 0.0 || v == 1.0, aapl_sm_mat[:, 2])
        @test all(isfinite, aapl_sm_mat[:, 1])
    end

    @testset "ParabolicSAR" begin
        # Type checks: Matrix input returns Matrix output
        @test ParabolicSAR(vec2) isa Matrix{Float64}
        psar = ParabolicSAR(vec2)
        @test size(psar, 2) == 2  # [Value, Direction]

        # TSFrame input returns TSFrame output
        res = ParabolicSAR(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "ParabolicSAR_Value"
        @test names(res)[2] == "ParabolicSAR_Direction"

        # Custom parameters
        @test ParabolicSAR(data_ts; af_start=0.01, af_step=0.01, af_max=0.10) isa TSFrame

        # Direction values should be only 1.0 or -1.0
        @test all(d -> d == 1.0 || d == -1.0, psar[:, 2])

        # No NaN/Inf in output
        @test !any(isnan, psar)
        @test !any(isinf, psar)

        # Value should be positive for positive prices
        pos_prices = zeros(50, 2)
        for i in 1:50
            base = 100.0 + Float64(i)
            pos_prices[i, 1] = base + 1.0   # High
            pos_prices[i, 2] = base - 1.0   # Low
        end
        psar_pos = ParabolicSAR(pos_prices)
        @test all(v -> v > 0.0, psar_pos[:, 1])

        # Monotonically rising prices should eventually give uptrend (Direction=1.0)
        rising = hcat([10.0+i for i in 1:30], [8.0+i for i in 1:30])
        psar_rise = ParabolicSAR(rising)
        @test psar_rise[end, 2] == 1.0  # uptrend

        # Monotonically falling prices should eventually give downtrend (Direction=-1.0)
        falling = hcat([100.0-i for i in 1:30], [98.0-i for i in 1:30])
        psar_fall = ParabolicSAR(falling)
        @test psar_fall[end, 2] == -1.0  # downtrend

        # Reversals: alternating up/down prices should cause direction flips
        alternating = zeros(40, 2)
        for i in 1:40
            if mod(div(i - 1, 5), 2) == 0  # 5-bar up, 5-bar down cycles
                alternating[i, 1] = 50.0 + mod(i - 1, 5) * 3.0 + 2.0  # High
                alternating[i, 2] = 50.0 + mod(i - 1, 5) * 3.0         # Low
            else
                alternating[i, 1] = 65.0 - mod(i - 1, 5) * 3.0 + 2.0  # High
                alternating[i, 2] = 65.0 - mod(i - 1, 5) * 3.0         # Low
            end
        end
        psar_alt = ParabolicSAR(alternating; af_start=0.02, af_step=0.02, af_max=0.20)
        directions = psar_alt[:, 2]
        # There should be at least one direction change
        has_flip = any(i -> directions[i] != directions[i-1], 2:40)
        @test has_flip

        # Numerical validation with known sequence: uptrend then reversal
        prices = [10.0 9.0;   # High Low
                  11.0 10.0;
                  12.0 11.0;
                  13.0 12.0;
                  12.0 10.0;  # reversal signal
                  11.0 9.0]
        r = ParabolicSAR(prices)
        # i=1: initial SAR = Low[1] = 9.0, Direction = uptrend
        @test r[1, 1] ≈ 9.0 atol=1e-10
        @test r[1, 2] == 1.0

        # i=2: new_sar = 9.0 + 0.02*(10.0-9.0) = 9.02, clamped to min(9.02, 9.0) = 9.0
        @test r[2, 1] ≈ 9.0 atol=1e-10
        @test r[2, 2] == 1.0

        # i=3: new_sar = 9.0 + 0.04*(11.0-9.0) = 9.08, clamped min(9.08,10.0,9.0) = 9.0
        @test r[3, 1] ≈ 9.0 atol=1e-10
        @test r[3, 2] == 1.0

        # i=4: new_sar = 9.0 + 0.06*(12.0-9.0) = 9.18
        @test r[4, 1] ≈ 9.18 atol=1e-10
        @test r[4, 2] == 1.0

        # i=5: new_sar = 9.18 + 0.08*(13.0-9.18) = 9.4856
        @test r[5, 1] ≈ 9.4856 atol=1e-10
        @test r[5, 2] == 1.0

        # i=6: reversal to downtrend, SAR = previous EP = 13.0
        @test r[6, 1] ≈ 13.0 atol=1e-10
        @test r[6, 2] == -1.0

        # Input validation: wrong column count throws error
        @test_throws ArgumentError ParabolicSAR(rand(10, 3))  # 3 columns
        @test_throws ArgumentError ParabolicSAR(rand(10, 1))  # 1 column

        # AAPL smoke test
        psar_aapl = ParabolicSAR(data_ts)
        @test psar_aapl isa TSFrame
        @test size(psar_aapl)[1] == size(data_ts)[1]
        aapl_mat = ParabolicSAR(data_ts[:, [:High, :Low]] |> Matrix)
        @test all(d -> d == 1.0 || d == -1.0, aapl_mat[:, 2])
        # SAR values should be within a reasonable range of AAPL prices
        aapl_highs = data_ts[:, :High] |> Vector
        aapl_lows = data_ts[:, :Low] |> Vector
        price_min = minimum(aapl_lows) * 0.5
        price_max = maximum(aapl_highs) * 1.5
        @test all(v -> price_min <= v <= price_max, aapl_mat[:, 1])
    end

    @testset "Ichimoku" begin
        # --- Matrix core: shape and type ---
        # Fixed realistic prices instead of rand()
        prices = zeros(100, 3)
        for i in 1:100
            base = 100.0 + 0.5 * i + 2.0 * sin(i * 0.3)
            prices[i, 3] = base                              # Close
            prices[i, 1] = base + abs(1.5 + 0.5 * sin(i * 0.7))  # High > Close
            prices[i, 2] = base - abs(1.5 + 0.5 * cos(i * 0.7))  # Low < Close
        end

        r = Ichimoku(prices)
        @test r isa Matrix{Float64}
        @test size(r, 1) == size(prices, 1) + 26  # N + displacement rows
        @test size(r, 2) == 5

        # Custom displacement changes output row count
        r10 = Ichimoku(prices; displacement=10)
        @test size(r10, 1) == size(prices, 1) + 10

        # --- All finite values where not NaN ---
        finite_mask = .!isnan.(r[:, 1])
        @test all(isfinite.(r[finite_mask, 1]))

        # --- No Inf anywhere ---
        @test !any(isinf, r)

        # --- Tenkan/Kijun should be between overall min(Low) and max(High) ---
        overall_min = minimum(prices[:, 2])
        overall_max = maximum(prices[:, 1])
        for v in r[1:size(prices, 1), 1]
            @test overall_min <= v <= overall_max
        end
        for v in r[1:size(prices, 1), 2]
            @test overall_min <= v <= overall_max
        end

        # --- Senkou A/B: first `displacement` rows should be NaN ---
        @test all(isnan.(r[1:26, 3]))
        @test all(isnan.(r[1:26, 4]))

        # --- Senkou A/B values should be in range ---
        for v in filter(!isnan, r[:, 3])
            @test overall_min <= v <= overall_max
        end
        for v in filter(!isnan, r[:, 4])
            @test overall_min <= v <= overall_max
        end

        # --- Chikou Span: last displacement rows of output should be NaN ---
        # Chikou is stored at rows 1..(N-displacement), NaN elsewhere
        nrows_in = size(prices, 1)
        @test all(isnan.(r[(nrows_in - 26 + 1):(nrows_in + 26), 5]))

        # --- Chikou: first valid values should match Close values ---
        # output[i - displacement, 5] = Close[i] for i in (displacement+1):N
        # So output[1, 5] = Close[displacement+1]
        @test r[1, 5] ≈ prices[27, 3] atol=1e-10

        # --- Extended rows: Tenkan/Kijun should be NaN in future rows ---
        @test all(isnan.(r[(nrows_in + 1):(nrows_in + 26), 1]))
        @test all(isnan.(r[(nrows_in + 1):(nrows_in + 26), 2]))

        # --- Numerical validation with known data ---
        # Simple known data: 10 bars, tenkan=3, kijun=5, senkou_b=5, displacement=3
        # Highs: [10,12,14,13,15,16,14,17,18,16]
        # Lows:  [8, 9, 11,10,12,13,11,14,15,13]
        # Close: [9, 11,13,12,14,15,13,16,17,15]
        known_h = [10.0, 12.0, 14.0, 13.0, 15.0, 16.0, 14.0, 17.0, 18.0, 16.0]
        known_l = [8.0, 9.0, 11.0, 10.0, 12.0, 13.0, 11.0, 14.0, 15.0, 13.0]
        known_c = [9.0, 11.0, 13.0, 12.0, 14.0, 15.0, 13.0, 16.0, 17.0, 15.0]
        known_prices = hcat(known_h, known_l, known_c)

        rk = Ichimoku(known_prices; tenkan=3, kijun=5, senkou_b=5, displacement=3)
        @test size(rk) == (13, 5)  # 10 + 3

        # Tenkan at bar 1: max(10)/min(8) over 1 bar = (10+8)/2 = 9.0
        @test rk[1, 1] ≈ 9.0 atol=1e-10

        # Tenkan at bar 3: max(10,12,14)=14, min(8,9,11)=8 -> (14+8)/2 = 11.0
        @test rk[3, 1] ≈ 11.0 atol=1e-10

        # Tenkan at bar 5: max(14,13,15)=15, min(11,10,12)=10 -> (15+10)/2 = 12.5
        @test rk[5, 1] ≈ 12.5 atol=1e-10

        # Kijun at bar 5: max(10,12,14,13,15)=15, min(8,9,11,10,12)=8 -> (15+8)/2 = 11.5
        @test rk[5, 2] ≈ 11.5 atol=1e-10

        # Kijun at bar 1: max(10)/min(8) = (10+8)/2 = 9.0
        @test rk[1, 2] ≈ 9.0 atol=1e-10

        # Senkou A at bar 1+3=4: (Tenkan[1] + Kijun[1]) / 2 = (9+9)/2 = 9.0
        @test rk[4, 3] ≈ 9.0 atol=1e-10

        # Senkou A at bar 5+3=8: (Tenkan[5] + Kijun[5]) / 2 = (12.5+11.5)/2 = 12.0
        @test rk[8, 3] ≈ 12.0 atol=1e-10

        # Senkou B at bar 5+3=8: max(H[1..5])=15, min(L[1..5])=8 -> (15+8)/2 = 11.5
        @test rk[8, 4] ≈ 11.5 atol=1e-10

        # Chikou: output[i-3, 5] = Close[i] for i in 4..10
        # output[1, 5] = Close[4] = 12.0
        @test rk[1, 5] ≈ 12.0 atol=1e-10
        # output[7, 5] = Close[10] = 15.0
        @test rk[7, 5] ≈ 15.0 atol=1e-10
        # output[8..13, 5] should be NaN
        @test all(isnan.(rk[8:13, 5]))

        # First 3 rows of SenkouA/B should be NaN (displacement=3)
        @test all(isnan.(rk[1:3, 3]))
        @test all(isnan.(rk[1:3, 4]))

        # --- TSFrame wrapper ---
        ts_result = Ichimoku(data_ts)
        @test ts_result isa TSFrame
        @test nrow(ts_result) == nrow(data_ts) + 26  # extended by displacement
        @test names(ts_result) == ["Ichimoku_Tenkan", "Ichimoku_Kijun", "Ichimoku_SenkouA", "Ichimoku_SenkouB", "Ichimoku_Chikou"]

        # Future dates are properly generated
        orig_idx = index(data_ts)
        result_idx = index(ts_result)
        @test length(result_idx) == length(orig_idx) + 26
        @test result_idx[1:length(orig_idx)] == orig_idx  # original dates preserved
        @test result_idx[end] > orig_idx[end]             # future dates extend beyond

        # Custom displacement
        ts_d10 = Ichimoku(data_ts; displacement=10)
        @test nrow(ts_d10) == nrow(data_ts) + 10

        # Custom parameters
        @test Ichimoku(data_ts; tenkan=7, kijun=22, senkou_b=44, displacement=22) isa TSFrame

        # Input validation
        @test_throws ArgumentError Ichimoku(rand(10, 2))  # wrong column count
        @test_throws ArgumentError Ichimoku(rand(10, 3); tenkan=0)  # invalid period
        @test_throws ArgumentError Ichimoku(rand(10, 3); displacement=0)  # invalid displacement

        # AAPL smoke test
        ichimoku_aapl = Ichimoku(data_ts)
        @test ichimoku_aapl isa TSFrame
        @test nrow(ichimoku_aapl) == nrow(data_ts) + 26
    end

    @testset "Vortex" begin
        # Type checks: Matrix input returns Matrix output
        @test Vortex(vec3) isa Matrix{Float64}
        vx = Vortex(vec3)
        @test size(vx, 2) == 2  # [VIPlus, VIMinus]

        # TSFrame input returns TSFrame output
        res = Vortex(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "Vortex_VIPlus"
        @test names(res)[2] == "Vortex_VIMinus"

        # Custom parameters
        @test Vortex(data_ts; n=21) isa TSFrame

        # Length check
        @test size(vx, 1) == length(_high_col)

        # No Inf check
        @test !any(isinf, vx)
        @test all(isfinite, vx)

        # Bar 1 should be 0.0 (no previous bar -> vm_plus=0, vm_minus=0, tr=H-L only)
        # With n=14 default, bar 1 has only 1 element in window.
        # vm_plus[1]=0, vm_minus[1]=0, tr[1]=H[1]-L[1]
        # vi_plus[1] = 0/tr[1] = 0, vi_minus[1] = 0/tr[1] = 0
        @test vx[1, 1] == 0.0
        @test vx[1, 2] == 0.0

        # Behavioral test: strong uptrend data -> VI+ should be > VI-
        uptrend = zeros(30, 3)
        for i in 1:30
            base = 50.0 + Float64(i) * 2.0
            uptrend[i, 1] = base + 1.0   # High
            uptrend[i, 2] = base - 1.0   # Low
            uptrend[i, 3] = base          # Close
        end
        vx_up = Vortex(uptrend; n=14)
        # After warmup, VI+ should dominate
        @test vx_up[end, 1] > vx_up[end, 2]

        # Behavioral test: strong downtrend data -> VI- should be > VI+
        downtrend = zeros(30, 3)
        for i in 1:30
            base = 150.0 - Float64(i) * 2.0
            downtrend[i, 1] = base + 1.0   # High
            downtrend[i, 2] = base - 1.0   # Low
            downtrend[i, 3] = base          # Close
        end
        vx_down = Vortex(downtrend; n=14)
        @test vx_down[end, 2] > vx_down[end, 1]

        # Hand-calculated test with small data
        # 5 bars: H=[10,12,11,13,14], L=[8,9,8,10,11], C=[9,11,9,12,13]
        small = [10.0 8.0 9.0; 12.0 9.0 11.0; 11.0 8.0 9.0; 13.0 10.0 12.0; 14.0 11.0 13.0]
        vx_s = Vortex(small; n=3)
        # Bar 1: vm+=0, vm-=0, tr=10-8=2
        @test vx_s[1, 1] == 0.0
        @test vx_s[1, 2] == 0.0
        # Bar 2: vm+=|12-8|=4, vm-=|9-10|=1, tr=max(12-9,|12-9|,|9-9|)=3
        # Bar 3: vm+=|11-9|=2, vm-=|8-12|=4, tr=max(11-8,|11-11|,|8-11|)=3
        # Bar 4 (n=3 window covers bars 2,3,4):
        #   vm+[4]=|13-8|=5, vm-[4]=|10-11|=1, tr[4]=max(13-10,|13-9|,|10-9|)=4
        #   sum_vm+ = 4+2+5=11, sum_vm- = 1+4+1=6, sum_tr = 3+3+4=10
        #   vi+ = 11/10 = 1.1, vi- = 6/10 = 0.6
        @test vx_s[4, 1] ≈ 1.1 atol=1e-10
        @test vx_s[4, 2] ≈ 0.6 atol=1e-10

        # Input validation
        @test_throws ArgumentError Vortex(rand(10, 2))  # wrong column count
        @test_throws ArgumentError Vortex(rand(10, 4))  # wrong column count
        @test_throws ArgumentError Vortex(rand(10, 3); n=0)  # invalid period

        # AAPL smoke test
        vortex_aapl = Vortex(data_ts)
        @test vortex_aapl isa TSFrame
        @test size(vortex_aapl)[1] == size(data_ts)[1]
    end

    # Open column data for PivotPoints tests (same length as _high_col)
    _open_col = [
        50.0, 50.8, 49.3, 51.8, 52.6, 51.2, 53.7, 54.6, 52.9, 55.5,
        56.4, 54.5, 57.5, 58.7, 56.3, 59.6, 60.8, 58.4, 61.7, 62.9,
        60.5, 63.8, 65.0, 62.6, 65.9, 67.1, 64.7, 68.0, 69.2, 66.8,
        70.0, 70.8, 68.5, 72.0, 72.8, 70.4, 74.1, 74.9, 72.7, 76.0,
        76.8, 74.6, 77.7, 78.5, 76.3, 79.6, 80.4, 78.2, 81.5, 82.3,
        80.1, 83.4, 84.2, 82.0, 85.3, 86.1, 83.9, 87.2, 88.0, 85.8,
        88.9, 89.7, 87.5, 90.8, 91.6, 89.4, 92.7, 93.5, 91.3, 94.6,
        95.4, 93.2, 96.5, 97.3, 95.1, 98.4, 99.2, 97.0, 100.3, 101.1,
        98.9, 102.0, 102.8, 100.6, 103.9, 104.7, 102.5, 105.8, 106.6, 104.4,
        107.7, 108.5, 106.3, 109.6, 110.4, 108.2, 111.5, 112.3, 110.1, 113.4
    ]

    vec4 = hcat(_high_col, _low_col, _close_col, _open_col)

    @testset "PivotPoints" begin
        # Type checks: Matrix input returns Matrix output
        @test PivotPoints(vec4) isa Matrix{Float64}
        pp = PivotPoints(vec4)
        @test size(pp, 2) == 7  # [Pivot, R1, R2, R3, S1, S2, S3]

        # TSFrame input returns TSFrame output
        res = PivotPoints(data_ts)
        @test res isa TSFrame
        @test names(res) == ["PivotPoints_Pivot", "PivotPoints_R1", "PivotPoints_R2",
                             "PivotPoints_R3", "PivotPoints_S1", "PivotPoints_S2", "PivotPoints_S3"]

        # No Inf check
        @test !any(isinf, pp)

        # --- Classic method: hand-calculated ---
        # Single bar: H=110, L=100, C=105, O=102
        single = [110.0 100.0 105.0 102.0]
        pp_c = PivotPoints(single; method=:Classic)
        P_c = (110.0 + 100.0 + 105.0) / 3.0  # = 105.0
        @test pp_c[1, 1] ≈ P_c atol=1e-10             # Pivot
        @test pp_c[1, 2] ≈ 2.0 * P_c - 100.0 atol=1e-10  # R1 = 110.0
        @test pp_c[1, 3] ≈ P_c + 10.0 atol=1e-10      # R2 = 115.0
        @test pp_c[1, 4] ≈ 110.0 + 2.0 * (P_c - 100.0) atol=1e-10  # R3 = 120.0
        @test pp_c[1, 5] ≈ 2.0 * P_c - 110.0 atol=1e-10  # S1 = 100.0
        @test pp_c[1, 6] ≈ P_c - 10.0 atol=1e-10      # S2 = 95.0
        @test pp_c[1, 7] ≈ 100.0 - 2.0 * (110.0 - P_c) atol=1e-10  # S3 = 90.0

        # Classic level ordering: S3 < S2 < S1 < P < R1 < R2 < R3
        @test pp_c[1, 7] < pp_c[1, 6] < pp_c[1, 5] < pp_c[1, 1] < pp_c[1, 2] < pp_c[1, 3] < pp_c[1, 4]

        # --- Fibonacci method: hand-calculated ---
        pp_f = PivotPoints(single; method=:Fibonacci)
        P_f = (110.0 + 100.0 + 105.0) / 3.0  # = 105.0
        R_f = 10.0  # H - L
        @test pp_f[1, 1] ≈ P_f atol=1e-10
        @test pp_f[1, 2] ≈ P_f + 0.382 * R_f atol=1e-10  # R1 = 108.82
        @test pp_f[1, 3] ≈ P_f + 0.618 * R_f atol=1e-10  # R2 = 111.18
        @test pp_f[1, 4] ≈ P_f + 1.000 * R_f atol=1e-10  # R3 = 115.0
        @test pp_f[1, 5] ≈ P_f - 0.382 * R_f atol=1e-10  # S1 = 101.18
        @test pp_f[1, 6] ≈ P_f - 0.618 * R_f atol=1e-10  # S2 = 98.82
        @test pp_f[1, 7] ≈ P_f - 1.000 * R_f atol=1e-10  # S3 = 95.0

        # Fibonacci level ordering
        @test pp_f[1, 7] < pp_f[1, 6] < pp_f[1, 5] < pp_f[1, 1] < pp_f[1, 2] < pp_f[1, 3] < pp_f[1, 4]

        # --- Woodie method: uses Open, NOT Close ---
        pp_w = PivotPoints(single; method=:Woodie)
        P_w = (110.0 + 100.0 + 2.0 * 102.0) / 4.0  # = 103.5 (uses Open=102)
        @test pp_w[1, 1] ≈ P_w atol=1e-10
        @test pp_w[1, 2] ≈ 2.0 * P_w - 100.0 atol=1e-10  # R1 = 107.0
        @test pp_w[1, 3] ≈ P_w + 10.0 atol=1e-10      # R2 = 113.5
        @test pp_w[1, 5] ≈ 2.0 * P_w - 110.0 atol=1e-10  # S1 = 97.0

        # Woodie P differs from Classic P
        @test P_w != P_c

        # --- Camarilla method ---
        pp_cam = PivotPoints(single; method=:Camarilla)
        P_cam = (110.0 + 100.0 + 105.0) / 3.0
        R_cam = 10.0
        C_cam = 105.0
        @test pp_cam[1, 1] ≈ P_cam atol=1e-10
        @test pp_cam[1, 2] ≈ C_cam + 1.1 * R_cam / 12.0 atol=1e-10  # R1
        @test pp_cam[1, 3] ≈ C_cam + 1.1 * R_cam / 6.0 atol=1e-10   # R2
        @test pp_cam[1, 4] ≈ C_cam + 1.1 * R_cam / 4.0 atol=1e-10   # R3
        @test pp_cam[1, 5] ≈ C_cam - 1.1 * R_cam / 12.0 atol=1e-10  # S1
        @test pp_cam[1, 6] ≈ C_cam - 1.1 * R_cam / 6.0 atol=1e-10   # S2
        @test pp_cam[1, 7] ≈ C_cam - 1.1 * R_cam / 4.0 atol=1e-10   # S3

        # Camarilla level ordering
        @test pp_cam[1, 7] < pp_cam[1, 6] < pp_cam[1, 5] < pp_cam[1, 1] < pp_cam[1, 2] < pp_cam[1, 3] < pp_cam[1, 4]

        # --- DeMark method ---
        # Case 1: C < O -> X = H + 2L + C
        demark1 = [110.0 100.0 101.0 108.0]  # C=101 < O=108
        pp_d1 = PivotPoints(demark1; method=:DeMark)
        X1 = 110.0 + 2.0 * 100.0 + 101.0  # = 411.0
        @test pp_d1[1, 1] ≈ X1 / 4.0 atol=1e-10       # Pivot = 102.75
        @test pp_d1[1, 2] ≈ X1 / 2.0 - 100.0 atol=1e-10  # R1 = 105.5
        @test pp_d1[1, 5] ≈ X1 / 2.0 - 110.0 atol=1e-10  # S1 = 95.5
        # R2, R3, S2, S3 should be NaN
        @test isnan(pp_d1[1, 3])
        @test isnan(pp_d1[1, 4])
        @test isnan(pp_d1[1, 6])
        @test isnan(pp_d1[1, 7])

        # Case 2: C > O -> X = 2H + L + C
        demark2 = [110.0 100.0 108.0 101.0]  # C=108 > O=101
        pp_d2 = PivotPoints(demark2; method=:DeMark)
        X2 = 2.0 * 110.0 + 100.0 + 108.0  # = 428.0
        @test pp_d2[1, 1] ≈ X2 / 4.0 atol=1e-10       # Pivot = 107.0
        @test pp_d2[1, 2] ≈ X2 / 2.0 - 100.0 atol=1e-10  # R1 = 114.0
        @test pp_d2[1, 5] ≈ X2 / 2.0 - 110.0 atol=1e-10  # S1 = 104.0

        # Case 3: C == O -> X = H + L + 2C
        demark3 = [110.0 100.0 105.0 105.0]  # C=105 == O=105
        pp_d3 = PivotPoints(demark3; method=:DeMark)
        X3 = 110.0 + 100.0 + 2.0 * 105.0  # = 420.0
        @test pp_d3[1, 1] ≈ X3 / 4.0 atol=1e-10       # Pivot = 105.0
        @test pp_d3[1, 2] ≈ X3 / 2.0 - 100.0 atol=1e-10  # R1 = 110.0
        @test pp_d3[1, 5] ≈ X3 / 2.0 - 110.0 atol=1e-10  # S1 = 100.0

        # DeMark: Pivot column should NOT be NaN, R2/R3/S2/S3 should be NaN
        pp_d_multi = PivotPoints(vec4; method=:DeMark)
        @test !any(isnan, pp_d_multi[:, 1])  # Pivot
        @test !any(isnan, pp_d_multi[:, 2])  # R1
        @test !any(isnan, pp_d_multi[:, 5])  # S1
        @test all(isnan, pp_d_multi[:, 3])   # R2
        @test all(isnan, pp_d_multi[:, 4])   # R3
        @test all(isnan, pp_d_multi[:, 6])   # S2
        @test all(isnan, pp_d_multi[:, 7])   # S3

        # All methods should work with TSFrame
        @test PivotPoints(data_ts; method=:Classic) isa TSFrame
        @test PivotPoints(data_ts; method=:Fibonacci) isa TSFrame
        @test PivotPoints(data_ts; method=:Woodie) isa TSFrame
        @test PivotPoints(data_ts; method=:Camarilla) isa TSFrame
        @test PivotPoints(data_ts; method=:DeMark) isa TSFrame

        # Input validation
        @test_throws ArgumentError PivotPoints(rand(10, 3))  # wrong column count
        @test_throws ArgumentError PivotPoints(rand(10, 2))  # wrong column count
        @test_throws ArgumentError PivotPoints(rand(10, 4); method=:Invalid)  # invalid method

        # AAPL smoke test
        pp_aapl = PivotPoints(data_ts)
        @test pp_aapl isa TSFrame
        @test size(pp_aapl)[1] == size(data_ts)[1]
    end
end
