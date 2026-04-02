using Test
using Foxtail
using TSFrames
using CSV

aapl = CSV.read(joinpath(@__DIR__, "aapl.csv"), TSFrame)
data_ts = aapl[end-100:end]

@testset "Indicators SISO" begin
    data_vec = collect(1.0:50.0)

    # Shared small input for numerical validation
    small = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

    @testset "ALMA" begin
        @test ALMA(data_vec) isa Vector{Float64}
        @test ALMA(data_vec; n=5) isa Vector{Float64}
        @test ALMA(data_ts) isa TSFrame
        ma = ALMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "ALMA_50"
        @test ALMA(data_ts; offset=0.9, sigma=5.5, n=20) isa TSFrame

        # Numerical validation
        # ALMA n=3: Gaussian-weighted MA. Reference computed via Foxtail.
        r = ALMA(small; n=3)
        @test length(r) == 10
        @test r[1] ≈ 1.0 atol=1e-10                  # first value = price[1]
        @test r[3] ≈ 2.6856736002382617 atol=1e-8     # full window at i=3
        @test r[end] ≈ 9.685673600238262 atol=1e-8     # steady-state offset
        # Once window is full, ALMA(i) - ALMA(i-1) ≈ 1.0 for linear data
        @test r[6] - r[5] ≈ 1.0 atol=1e-10
    end

    @testset "EMA" begin
        @test EMA(data_vec) isa Vector{Float64}
        @test EMA(data_vec; n=5) isa Vector{Float64}
        @test EMA(data_ts) isa TSFrame
        ma = EMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "EMA_50"

        # Numerical validation
        # EMA n=3: alpha=2/(1+i) for i<=3, then alpha=2/(1+3)=0.5
        r = EMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10                          # init: data[1]
        @test r[2] ≈ 5/3 atol=1e-10                          # alpha=2/3: 2*(2/3)+1*(1/3)
        @test r[3] ≈ 7/3 atol=1e-10                          # alpha=0.5: 3*0.5+5/3*0.5
        @test r[4] ≈ 4*0.5 + 7/3*0.5 atol=1e-10             # post-init: alpha=0.5
        @test r[end] ≈ 9.002604166666666 atol=1e-8           # converges toward data

        # EMA with different period
        r5 = EMA(small; n=5)
        @test r5[5] ≈ 11/3 atol=1e-10                        # alpha=2/6=1/3 at i=5
        @test r5[end] ≈ 8.087791495198903 atol=1e-8
    end

    @testset "DEMA" begin
        @test DEMA(data_vec) isa Vector{Float64}
        @test DEMA(data_vec; n=5) isa Vector{Float64}
        @test DEMA(data_ts) isa TSFrame
        ma = DEMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "DEMA_50"

        # Numerical validation
        # DEMA = 2*EMA(price) - EMA(EMA(price))
        r = DEMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10                          # first value
        @test r[2] ≈ 1.8888888888888888 atol=1e-8
        @test r[3] ≈ 2.7777777777777777 atol=1e-8
        @test r[end] ≈ 9.989149305555555 atol=1e-8           # near 10 for linear data
        # DEMA should track linear data more closely than EMA
        ema_r = EMA(small; n=3)
        @test abs(r[end] - 10.0) < abs(ema_r[end] - 10.0)
    end

    @testset "HMA" begin
        @test HMA(data_vec) isa Vector{Float64}
        @test HMA(data_vec; n=5) isa Vector{Float64}
        @test HMA(data_ts) isa TSFrame
        ma = HMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "HMA_50"

        # Numerical validation
        # HMA n=4: WMA[sqrt(4)=2]( 2*WMA[2] - WMA[4] )
        r = HMA(small; n=4)
        @test r[1] ≈ 1.0 atol=1e-10
        @test r[end] ≈ 10.0 atol=1e-10                       # HMA perfectly tracks linear data
        @test r[5] ≈ 5.0 atol=1e-8
        @test r[6] ≈ 6.0 atol=1e-8
    end

    @testset "JMA" begin
        @test JMA(data_vec) isa Vector{Float64}
        @test JMA(data_vec; n=5) isa Vector{Float64}
        @test JMA(data_ts) isa TSFrame
        ma = JMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "JMA_50"
        @test JMA(data_ts; phase=55.0, n=25) isa TSFrame
        @test JMA(data_ts; phase=-55.0, n=25) isa TSFrame

        # Numerical validation
        # JMA is adaptive; verify basic properties
        r = JMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10                          # first value = price[1]
        @test length(r) == 10
        # JMA should be monotonically increasing for monotonic input
        for i in 2:10
            @test r[i] >= r[i-1] - 1e-10
        end
    end

    @testset "KAMA" begin
        @test KAMA(data_vec) isa Vector{Float64}
        @test KAMA(data_vec; n=5) isa Vector{Float64}
        @test KAMA(data_ts) isa TSFrame
        ma = KAMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "KAMA_50"
        @test KAMA(data_ts; fast=5, slow=25, n=15) isa TSFrame

        # Numerical validation
        # KAMA n=3: Kaufman Adaptive MA
        r = KAMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10
        @test r[2] ≈ 1.4444444444444442 atol=1e-8
        @test r[3] ≈ 2.135802469135802 atol=1e-8
        @test r[end] ≈ 6.8882667553034 atol=1e-6
        # KAMA should lag behind for trending data
        @test r[end] < small[end]
    end

    @testset "RSI" begin
        @test RSI(data_vec) isa Vector{Float64}
        @test RSI(data_vec; n=5) isa Vector{Float64}
        @test RSI(data_ts) isa TSFrame
        @test RSI(data_ts; ma_type=:EMA) isa TSFrame
        @test RSI(data_ts; ma_type=:SMMA) isa TSFrame
        ma = RSI(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "RSI_50"
        @test RMA(data_ts; n=25) isa TSFrame

        # Numerical validation
        # RSI first value is always 0 (undefined)
        rsi_data = [44.0, 44.34, 44.09, 43.61, 44.33, 44.83, 45.10,
                    45.42, 45.84, 46.08, 45.89, 46.03, 45.61, 46.28,
                    46.28, 46.00, 46.03, 46.41, 46.22, 45.64]
        r = RSI(rsi_data; n=14)
        @test r[1] ≈ 0.0 atol=1e-10                          # first is undefined
        @test r[end] ≈ 60.13716896582762 atol=1e-6

        # RSI with SMA: simple small dataset
        rsi_small = [10.0, 12.0, 11.0, 13.0, 12.5, 14.0, 13.0, 15.0, 14.5, 16.0]
        r2 = RSI(rsi_small; n=3, ma_type=:SMA)
        @test r2[1] ≈ 0.0 atol=1e-10
        @test r2[2] ≈ 100.0 atol=1e-10                       # pure gain -> RSI=100
        @test r2[end] ≈ 87.5 atol=1e-6

        # RSI should be bounded [0, 100] (except first which is 0)
        for i in 2:length(r)
            @test 0.0 <= r[i] <= 100.0
        end

        # Monotonically increasing data -> RSI = 100 at index 2
        mono = collect(1.0:20.0)
        r_mono = RSI(mono; n=5)
        @test r_mono[2] ≈ 100.0 atol=1e-10
    end

    @testset "SMA" begin
        @test SMA(data_vec) isa Vector{Float64}
        @test SMA(data_vec; n=5) isa Vector{Float64}
        @test SMA(data_ts) isa TSFrame
        ma = SMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "SMA_50"
        @test RMA(data_ts; n=25) isa TSFrame

        # Numerical validation
        # SMA n=3: arithmetic mean over sliding window
        r = SMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10                          # 1/1
        @test r[2] ≈ 1.5 atol=1e-10                          # (1+2)/2
        @test r[3] ≈ 2.0 atol=1e-10                          # (1+2+3)/3 = 2.0
        @test r[4] ≈ 3.0 atol=1e-10                          # (2+3+4)/3 = 3.0
        @test r[5] ≈ 4.0 atol=1e-10                          # (3+4+5)/3 = 4.0
        @test r[end] ≈ 9.0 atol=1e-10                        # (8+9+10)/3 = 9.0

        # SMA n=5
        r5 = SMA(small; n=5)
        @test r5[5] ≈ 3.0 atol=1e-10                         # (1+2+3+4+5)/5 = 3.0
        @test r5[end] ≈ 8.0 atol=1e-10                       # (6+7+8+9+10)/5 = 8.0
    end

    @testset "SMMA" begin
        @test SMMA(data_vec) isa Vector{Float64}
        @test SMMA(data_vec; n=5) isa Vector{Float64}
        @test SMMA(data_ts) isa TSFrame
        ma = SMMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "SMMA_50"

        # Numerical validation
        # SMMA n=3: alpha=1/i for i<=3, then alpha=1/3
        r = SMMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10                          # init: data[1]
        @test r[2] ≈ 1.5 atol=1e-10                          # alpha=1/2: 2*0.5+1*0.5
        @test r[3] ≈ 2.0 atol=1e-10                          # alpha=1/3: 3/3+1.5*2/3
        @test r[4] ≈ 8/3 atol=1e-10                          # alpha=1/3: 4/3+2*2/3
        @test r[end] ≈ 8.058527663465936 atol=1e-8

        # SMMA n=5
        r5 = SMMA(small; n=5)
        @test r5[5] ≈ 3.0 atol=1e-10                         # matches SMA at period end
        @test r5[end] ≈ 6.655360000000001 atol=1e-8           # more lag than EMA
    end

    @testset "T3" begin
        @test T3(data_vec) isa Vector{Float64}
        @test T3(data_vec; n=5) isa Vector{Float64}
        @test T3(data_ts) isa TSFrame
        ma = T3(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "T3_50"
        @test T3(data_ts;n=25, a=0.6) isa TSFrame

        # Numerical validation
        # T3 is built from DEMA layers; verify basic properties
        r = T3(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10                          # first value
        @test length(r) == 10
        # T3 should be monotonically increasing for monotonic input
        for i in 2:10
            @test r[i] >= r[i-1] - 1e-6
        end
    end

    @testset "TEMA" begin
        @test TEMA(data_vec) isa Vector{Float64}
        @test TEMA(data_vec; n=5) isa Vector{Float64}
        @test TEMA(data_ts) isa TSFrame
        ma = TEMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "TEMA_50"

        # Numerical validation
        # TEMA = (EMA1 - EMA2)*3 + EMA3
        r = TEMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10
        @test r[2] ≈ 1.9629629629629632 atol=1e-8
        @test r[3] ≈ 2.9259259259259256 atol=1e-8
        @test r[end] ≈ 10.014612268518519 atol=1e-8          # overshoots slightly
        # TEMA tracks linear data very closely
        @test abs(r[end] - 10.0) < 0.02
    end

    @testset "TMA" begin
        @test TMA(data_vec) isa Vector{Float64}
        @test TMA(data_vec; n=5) isa Vector{Float64}
        @test TMA(data_ts) isa TSFrame
        ma = TMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "TMA_50"
        @test TRIMA(data_ts; n=25) isa TSFrame

        # Numerical validation
        # TMA n=3: SMA(SMA(price; n=3); n=div(4,2)=2)
        r = TMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10
        @test r[2] ≈ 1.25 atol=1e-10                         # SMA of [1.0,1.5] = 1.25
        @test r[3] ≈ 1.75 atol=1e-10                         # SMA of [1.5,2.0] = 1.75
        @test r[4] ≈ 2.5 atol=1e-10                          # SMA of [2.0,3.0] = 2.5
        @test r[end] ≈ 8.5 atol=1e-10                        # SMA of [8.0,9.0] = 8.5
        # TMA lags behind SMA
        sma_r = SMA(small; n=3)
        @test r[end] < sma_r[end]
    end

    @testset "WMA" begin
        @test WMA(data_vec) isa Vector{Float64}
        @test WMA(data_vec; n=5) isa Vector{Float64}
        @test WMA(data_ts) isa TSFrame
        ma = WMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "WMA_50"

        # Numerical validation
        # WMA n=3: weights [1,2,3], denom=6
        r = WMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10                          # (1*1)/1
        @test r[2] ≈ 5/3 atol=1e-10                          # (1*1+2*2)/3 = 5/3
        @test r[3] ≈ 14/6 atol=1e-10                         # (1+4+9)/6 = 14/6
        @test r[4] ≈ 10/3 atol=1e-10                         # (1*2+2*3+3*4)/6 = 20/6 = 10/3
        @test r[end] ≈ 28/3 atol=1e-10                       # (1*8+2*9+3*10)/6 = 56/6

        # WMA n=5
        r5 = WMA(small; n=5)
        @test r5[5] ≈ 11/3 atol=1e-10                        # (1+4+9+16+25)/15 = 55/15
        @test r5[end] ≈ 26/3 atol=1e-10                      # (6+14+24+36+50)/15 = 130/15
    end

    @testset "ZLEMA" begin
        @test ZLEMA(data_vec) isa Vector{Float64}
        @test ZLEMA(data_vec; n=5) isa Vector{Float64}
        @test ZLEMA(data_ts) isa TSFrame
        ma = ZLEMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "ZLEMA_50"

        # Numerical validation
        # ZLEMA n=3: zero-lag EMA using modified price = 2*price - price[lag]
        r = ZLEMA(small; n=3)
        @test r[1] ≈ 1.0 atol=1e-10                          # init: data[1]
        @test r[end] ≈ 9.998697916666666 atol=1e-8            # nearly perfect tracking
        # ZLEMA tracks linear data better than standard EMA
        ema_r = EMA(small; n=3)
        @test abs(r[end] - 10.0) < abs(ema_r[end] - 10.0)

        # ZLEMA n=5
        r5 = ZLEMA(small; n=5)
        @test r5[end] ≈ 10.008779149519892 atol=1e-8
    end

    @testset "ROC" begin
        @test ROC(data_vec) isa Vector{Float64}
        @test ROC(data_vec; n=5) isa Vector{Float64}
        @test ROC(data_ts) isa TSFrame
        ma = ROC(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "ROC_50"

        # Numerical validation
        # ROC n=3: (P[i] - P[i-n]) / P[i-n] * 100
        r = ROC(small; n=3)
        @test length(r) == 10
        # Startup period: first n values are 0.0
        @test r[1] ≈ 0.0 atol=1e-10
        @test r[2] ≈ 0.0 atol=1e-10
        @test r[3] ≈ 0.0 atol=1e-10
        # ROC[4] = (4-1)/1 * 100 = 300.0
        @test r[4] ≈ 300.0 atol=1e-10
        # ROC[5] = (5-2)/2 * 100 = 150.0
        @test r[5] ≈ 150.0 atol=1e-10
        # ROC[10] = (10-7)/7 * 100 ≈ 42.857...
        @test r[10] ≈ 100.0 * 3.0 / 7.0 atol=1e-10

        # ROC n=1: simple 1-period percent change
        r1 = ROC(small; n=1)
        @test r1[1] ≈ 0.0 atol=1e-10
        @test r1[2] ≈ 100.0 atol=1e-10                       # (2-1)/1 * 100
        @test r1[3] ≈ 50.0 atol=1e-10                        # (3-2)/2 * 100

        # Zero-denominator guard: prices containing 0.0 should not produce Inf/NaN
        roc_zero = ROC([0.0, 1.0, 2.0, 3.0, 4.0]; n=1)
        @test !any(isnan, roc_zero) && !any(isinf, roc_zero)
        @test roc_zero[2] ≈ 0.0 atol=1e-10  # denominator is 0.0 -> guarded to 0.0

        # Input validation
        @test_throws ArgumentError ROC(rand(5); n=0)  # period must be positive
        @test_throws ArgumentError ROC(rand(3); n=5)  # length < period + 1
    end

    @testset "DPO" begin
        @test DPO(data_vec) isa Vector{Float64}
        @test DPO(data_vec; n=10) isa Vector{Float64}
        @test DPO(data_ts) isa TSFrame
        dpo = DPO(data_ts; n=20)
        @test dpo isa TSFrame
        @test names(dpo)[1] == "DPO_20"

        # Startup period: first shift values are 0.0
        # shift = div(20, 2) + 1 = 11
        r = DPO(data_vec; n=20)
        for i in 1:11
            @test r[i] ≈ 0.0 atol=1e-10
        end

        # For constant price data: DPO should be near 0 everywhere
        const_prices = fill(42.0, 50)
        r_const = DPO(const_prices; n=10)
        @test all(x -> abs(x) < 1e-10, r_const)

        # All values should be finite
        @test all(isfinite, DPO(data_vec))

        # Numerical validation with small data
        # DPO(n=4): shift = div(4,2)+1 = 3
        # SMA_4 of [1..10]: cumulative avg expanding then window
        r_small = DPO(small; n=4)
        sma4 = SMA(small; n=4)
        # For i <= 3 (shift): DPO = 0.0
        @test r_small[1] ≈ 0.0 atol=1e-10
        @test r_small[2] ≈ 0.0 atol=1e-10
        @test r_small[3] ≈ 0.0 atol=1e-10
        # For i = 4: DPO[4] = prices[4] - SMA[4-3] = 4.0 - SMA[1] = 4.0 - 1.0 = 3.0
        @test r_small[4] ≈ small[4] - sma4[1] atol=1e-10
        # For i = 7: DPO[7] = prices[7] - SMA[4] = 7.0 - SMA[4]
        @test r_small[7] ≈ small[7] - sma4[4] atol=1e-10
    end
end
