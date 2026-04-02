using Test
using Foxtail
using TSFrames
using CSV

aapl = CSV.read(joinpath(@__DIR__, "aapl.csv"), TSFrame)
data_ts = aapl[end-100:end]

@testset "Indicators SIMO" begin
    data_vec = collect(1.0:50.0)

    # Shared small input for numerical validation
    small = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

    @testset "BollingerBands" begin
        @test BB(data_vec) isa Matrix{Float64}
        @test BB(data_vec; n=25, num_std=3.0) isa Matrix{Float64}
        @test BB(data_ts) isa TSFrame
        @test BB(data_ts; n=25, num_std=3.0) isa TSFrame
        @test BB(data_ts; ma_type=:EMA) isa TSFrame
        @test BB(data_ts; ma_type=:SMMA) isa TSFrame
        ind = BB(data_ts)
        @test names(ind)[1] == "BB_Center"
        @test names(ind)[2] == "BB_Upper"
        @test names(ind)[3] == "BB_Lower"

        # Numerical validation
        # BB n=3, num_std=2.0: Center=SMA, Upper/Lower=Center +/- 2*std
        bb = BB(small; n=3, num_std=2.0)
        # Center = SMA n=3
        @test bb[3,1] ≈ 2.0 atol=1e-10                       # SMA([1,2,3])
        @test bb[4,1] ≈ 3.0 atol=1e-10                       # SMA([2,3,4])
        @test bb[end,1] ≈ 9.0 atol=1e-10                     # SMA([8,9,10])

        # At i=3: std of [1,2,3] = sqrt(2/3) ≈ 0.8165
        std3 = sqrt(2/3)
        @test bb[3,2] ≈ 2.0 + 2.0*std3 atol=1e-8             # upper
        @test bb[3,3] ≈ 2.0 - 2.0*std3 atol=1e-8             # lower

        # Band symmetry: upper - center == center - lower
        for i in 3:10
            @test (bb[i,2] - bb[i,1]) ≈ (bb[i,1] - bb[i,3]) atol=1e-10
        end

        # First value: no spread
        @test bb[1,1] ≈ 1.0 atol=1e-10
        @test bb[1,2] ≈ 1.0 atol=1e-10                       # std=0 for single point
        @test bb[1,3] ≈ 1.0 atol=1e-10
    end

    @testset "MACD" begin
        @test MACD(data_vec) isa Matrix{Float64}
        ind = MACD(data_ts)
        @test ind isa TSFrame
        @test names(ind)[1] == "MACD_Line"
        @test names(ind)[2] == "MACD_Signal"
        @test names(ind)[3] == "MACD_Histogram"

        # Numerical validation
        # MACD = EMA(fast) - EMA(slow); Signal = EMA(MACD); Histogram = MACD - Signal
        data30 = collect(1.0:30.0)
        m = MACD(data30; fast=3, slow=5, signal=3)
        # For linear data, fast EMA > slow EMA -> MACD line > 0
        @test m[end,1] ≈ 0.9999736010648235 atol=1e-6        # MACD line
        @test m[end,2] ≈ 0.9999472455913766 atol=1e-6        # Signal line
        @test m[end,3] ≈ m[end,1] - m[end,2] atol=1e-10     # Histogram = Line - Signal

        # MACD line should be positive for upward-trending data
        for i in 5:30
            @test m[i,1] > 0.0
        end

        # Histogram should converge to 0 for linear data
        @test abs(m[end,3]) < 0.001
    end

    @testset "MACD3" begin
        @test MACD3(data_vec) isa Matrix{Float64}
        ind = MACD3(data_ts)
        @test ind isa TSFrame
        @test names(ind)[1] == "MACD3_Fast"
        @test names(ind)[2] == "MACD3_Middle"
        @test names(ind)[3] == "MACD3_Slow"
        @test MACD3(data_ts; ma_type=:HAJ, fast=10, middle=30, slow=50) isa TSFrame
        @test MACD3(data_ts; ma_type=:KAMA, fast=10, middle=30, slow=50) isa TSFrame
        @test MACD3(data_ts; ma_type=:ALMA, fast=10, middle=30, slow=50) isa TSFrame

        # Numerical validation
        # MACD3 with EMA: fast-middle, fast-slow, middle-slow differences
        m = MACD3(data_vec)
        @test size(m) == (50, 3)
        # For linear data, all differences should be positive (fast > slow)
        # and converge. Check last values are positive.
        @test m[end,1] > 0.0                                  # fast - middle > 0
        @test m[end,2] > 0.0                                  # fast - slow > 0
        @test m[end,3] > 0.0                                  # middle - slow > 0
        # Middle line should be larger than fast and slow lines
        @test m[end,2] > m[end,1]
        @test m[end,2] > m[end,3]
    end

    @testset "Stochastic RSI" begin
        @test StochRSI(data_vec) isa Matrix{Float64}
        @test StochRSI(data_ts) isa TSFrame
        @test StochRSI(data_ts; ma_type=:EMA, k_smooth=3, d_smooth=5) isa TSFrame
        @test StochRSI(data_ts; ma_type=:SMMA, k_smooth=4, d_smooth=6) isa TSFrame
        @test StochRSI(data_ts; ma_type=:RMA, k_smooth=4, d_smooth=6) isa TSFrame
        @test StochRSI(data_ts; ma_type=:WMA, k_smooth=6, d_smooth=8) isa TSFrame
        ind = StochRSI(data_ts)
        @test names(ind)[1] == "StochRSI_K"
        @test names(ind)[2] == "StochRSI_D"

        # Numerical validation
        # For monotonically increasing data, RSI stays near 100,
        # so StochRSI should reflect that stability
        r = StochRSI(data_vec)
        @test size(r) == (50, 2)
        # K and D lines should be in [0, 100] range roughly
        # (smoothing may cause small overshoots but should be close)
        @test r[end,1] >= 0.0
        @test r[end,2] >= 0.0
    end

    @testset "PPO" begin
        @test PPO(data_vec) isa Matrix{Float64}
        ind = PPO(data_ts)
        @test ind isa TSFrame
        @test names(ind)[1] == "PPO_Line"
        @test names(ind)[2] == "PPO_Signal"
        @test names(ind)[3] == "PPO_Histogram"

        # Numerical validation
        # PPO_Line = (EMA_fast - EMA_slow) / EMA_slow * 100
        # Signal = EMA(PPO_Line; n=signal)
        # Histogram = PPO_Line - Signal
        data30 = collect(1.0:30.0)
        p = PPO(data30; fast=3, slow=5, signal=3)

        # Verify against manual calculation
        fast_ema = EMA(data30; n=3)
        slow_ema = EMA(data30; n=5)
        expected_line = @. (fast_ema - slow_ema) / slow_ema * 100
        expected_signal = EMA(expected_line; n=3)
        expected_hist = expected_line - expected_signal
        @test p[:, 1] ≈ expected_line atol=1e-10
        @test p[:, 2] ≈ expected_signal atol=1e-10
        @test p[:, 3] ≈ expected_hist atol=1e-10

        # Histogram = Line - Signal at every bar
        ppo_mat = PPO(data_vec)
        @test ppo_mat[:, 3] ≈ ppo_mat[:, 1] - ppo_mat[:, 2] atol=1e-10

        # For linear data, PPO_Line should be small (fast/slow EMAs converge)
        @test abs(p[end, 1]) < 10.0

        # Comparison with MACD: sign should be same direction
        m = MACD(data30; fast=3, slow=5, signal=3)
        for i in 5:30
            # When MACD line > 0, PPO line should also be > 0 (and vice versa)
            @test sign(p[i, 1]) == sign(m[i, 1])
        end

        # All values should be finite
        @test all(isfinite, PPO(data_vec))

        # Zero-denominator guard: prices starting at 0.0 should not produce Inf/NaN
        ppo_zero = PPO([0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0,
                        6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0,
                        16.0, 17.0, 18.0, 19.0, 20.0, 21.0]; fast=3, slow=5, signal=3)
        @test !any(isnan, ppo_zero) && !any(isinf, ppo_zero)

        # Input validation
        @test_throws ArgumentError PPO(rand(5))  # length < slow period
    end

    @testset "KST" begin
        @test KST(data_vec) isa Matrix{Float64}
        result = KST(data_vec)
        @test size(result, 2) == 2

        ind = KST(data_ts)
        @test ind isa TSFrame
        @test names(ind)[1] == "KST_Line"
        @test names(ind)[2] == "KST_Signal"

        # For linearly rising data: KST should be positive
        # (all ROC components positive for upward trend)
        r = KST(data_vec)
        # After warmup, KST line should be positive
        @test r[end, 1] > 0.0

        # All values should be finite
        @test all(isfinite, KST(data_vec))

        # Signal should converge toward Line for steady-state data
        # (both columns should be close at the end for linear input)
        @test abs(r[end, 1] - r[end, 2]) < abs(r[end, 1]) * 0.5 + 1e-10

        # Cross-reference numerical validation
        # Manually compute KST using Foxtail's ROC and SMA, then compare with KST()
        kst_prices = [44.0, 44.5, 44.3, 43.8, 44.9, 45.2, 45.0, 44.7, 45.5, 46.0,
                      46.3, 45.8, 46.5, 47.0, 46.8, 47.5, 48.0, 47.3, 48.2, 49.0,
                      48.5, 49.3, 50.0, 49.5, 50.5, 51.0, 50.2, 51.5, 52.0, 51.3,
                      52.5, 53.0, 52.2, 53.5, 54.0, 53.3, 54.5, 55.0, 54.2, 55.5]
        kst_r1, kst_r2, kst_r3, kst_r4 = 3, 5, 7, 10
        kst_s1, kst_s2, kst_s3, kst_s4 = 3, 4, 5, 6
        kst_sig = 4

        # Reference: replicate KST formula with Foxtail's ROC and SMA
        ref_roc1 = SMA(ROC(kst_prices; n=kst_r1); n=kst_s1)
        ref_roc2 = SMA(ROC(kst_prices; n=kst_r2); n=kst_s2)
        ref_roc3 = SMA(ROC(kst_prices; n=kst_r3); n=kst_s3)
        ref_roc4 = SMA(ROC(kst_prices; n=kst_r4); n=kst_s4)
        ref_kst = 1.0 .* ref_roc1 .+ 2.0 .* ref_roc2 .+ 3.0 .* ref_roc3 .+ 4.0 .* ref_roc4
        ref_signal = SMA(ref_kst; n=kst_sig)

        actual = KST(kst_prices; r1=kst_r1, r2=kst_r2, r3=kst_r3, r4=kst_r4,
                     s1=kst_s1, s2=kst_s2, s3=kst_s3, s4=kst_s4, signal=kst_sig)

        # KST line (column 1) should match reference exactly
        @test length(actual[:, 1]) == length(ref_kst)
        for i in eachindex(ref_kst)
            @test actual[i, 1] ≈ ref_kst[i] atol=1e-10
        end

        # Signal line (column 2) should match reference exactly
        for i in eachindex(ref_signal)
            @test actual[i, 2] ≈ ref_signal[i] atol=1e-10
        end

        # Sanity check: after full warmup, KST values should be non-zero
        @test actual[end, 1] != 0.0
        @test actual[end, 2] != 0.0
    end
end
