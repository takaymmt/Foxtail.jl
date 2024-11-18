@testset "Indicators" begin
    aapl = CSV.read(joinpath(dirname(@__FILE__), "aapl.csv"), TSFrame)
    data_ts = aapl[end-100:end]

    @testset "Indicators SISO" begin
        data_vec = collect(1.0:50.0)

        @testset "ALMA" begin
            @test ALMA(data_vec) isa Vector{Float64}
            @test ALMA(data_vec; n=5) isa Vector{Float64}
            @test ALMA(data_ts) isa TSFrame
            ma = ALMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "ALMA_50"
            @test ALMA(data_ts; offset=0.9, sigma=5.5, n=20) isa TSFrame
        end

        @testset "EMA" begin
            @test EMA(data_vec) isa Vector{Float64}
            @test EMA(data_vec; n=5) isa Vector{Float64}
            @test EMA(data_ts) isa TSFrame
            ma = EMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "EMA_50"
        end

        @testset "DEMA" begin
            @test DEMA(data_vec) isa Vector{Float64}
            @test DEMA(data_vec; n=5) isa Vector{Float64}
            @test DEMA(data_ts) isa TSFrame
            ma = DEMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "DEMA_50"
        end

        @testset "HMA" begin
            @test HMA(data_vec) isa Vector{Float64}
            @test HMA(data_vec; n=5) isa Vector{Float64}
            @test HMA(data_ts) isa TSFrame
            ma = HMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "HMA_50"
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
        end

        @testset "KAMA" begin
            @test KAMA(data_vec) isa Vector{Float64}
            @test KAMA(data_vec; n=5) isa Vector{Float64}
            @test KAMA(data_ts) isa TSFrame
            ma = KAMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "KAMA_50"
            @test KAMA(data_ts; fast=5, slow=25, n=15) isa TSFrame
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
        end

        @testset "SMA" begin
            @test SMA(data_vec) isa Vector{Float64}
            @test SMA(data_vec; n=5) isa Vector{Float64}
            @test SMA(data_ts) isa TSFrame
            ma = SMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "SMA_50"
            @test RMA(data_ts; n=25) isa TSFrame
        end

        @testset "SMMA" begin
            @test SMMA(data_vec) isa Vector{Float64}
            @test SMMA(data_vec; n=5) isa Vector{Float64}
            @test SMMA(data_ts) isa TSFrame
            ma = SMMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "SMMA_50"
        end

        @testset "T3" begin
            @test T3(data_vec) isa Vector{Float64}
            @test T3(data_vec; n=5) isa Vector{Float64}
            @test T3(data_ts) isa TSFrame
            ma = T3(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "T3_50"
            @test T3(data_ts;n=25, a=0.6) isa TSFrame
        end

        @testset "TEMA" begin
            @test TEMA(data_vec) isa Vector{Float64}
            @test TEMA(data_vec; n=5) isa Vector{Float64}
            @test TEMA(data_ts) isa TSFrame
            ma = TEMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "TEMA_50"
        end

        @testset "TMA" begin
            @test TMA(data_vec) isa Vector{Float64}
            @test TMA(data_vec; n=5) isa Vector{Float64}
            @test TMA(data_ts) isa TSFrame
            ma = TMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "TMA_50"
            @test TRIMA(data_ts; n=25) isa TSFrame
        end

        @testset "WMA" begin
            @test WMA(data_vec) isa Vector{Float64}
            @test WMA(data_vec; n=5) isa Vector{Float64}
            @test WMA(data_ts) isa TSFrame
            ma = WMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "WMA_50"
        end

        @testset "ZLEMA" begin
            @test ZLEMA(data_vec) isa Vector{Float64}
            @test ZLEMA(data_vec; n=5) isa Vector{Float64}
            @test ZLEMA(data_ts) isa TSFrame
            ma = ZLEMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "ZLEMA_50"
        end
    end

    @testset "Indicators MISO" begin
        vec2 = rand(100,2) * 100
        vec3 = rand(100,3) * 100
        vec4 = rand(100,4) * 100

        @testset "ADL" begin
            @test ADL(vec4) isa Vector{Float64}
            @test ADL(data_ts) isa TSFrame
            @test names(ADL(data_ts))[1] == "ADL"
        end

        @testset "ATR" begin
            @test ATR(vec3) isa Vector{Float64}
            @test ATR(vec3; n=42) isa Vector{Float64}
            @test ATR(vec3; n=42, ma_type=:SMA) isa Vector{Float64}
            @test ATR(vec3; n=42, ma_type=:SMMA) isa Vector{Float64}
            @test ATR(data_ts) isa TSFrame
            atr = ATR(data_ts; n=42)
            @test atr isa TSFrame
            @test names(atr)[1] == "ATR_42"
        end

        @testset "ChaikinOsc" begin
            @test ChaikinOsc(vec4) isa Vector{Float64}
            @test ChaikinOsc(vec4; fast=10, slow=30) isa Vector{Float64}
            @test ChaikinOsc(data_ts) isa TSFrame
            co = ChaikinOsc(data_ts; fast=10, slow=30)
            @test co isa TSFrame
            @test names(co)[1] == "ChaikinOsc"
        end

        @testset "OBV" begin
            @test OBV(vec2) isa Vector{Float64}
            res = OBV(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "OBV"
        end
    end

    @testset "Indicators SIMO" begin
        data_vec = collect(1.0:50.0)

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
        end

        @testset "MACD" begin
            @test MACD(data_vec) isa Matrix{Float64}
            ind = MACD(data_ts)
            @test ind isa TSFrame
            @test names(ind)[1] == "MACD_Line"
            @test names(ind)[2] == "MACD_Signal"
            @test names(ind)[3] == "MACD_Histogram"
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
        end
    end

    @testset "Indicators MIMO" begin
        vec3 = rand(100,3) * 100

        @testset "Stochastic" begin
            @test Stoch(vec3) isa Matrix{Float64}
            res = Stoch(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "Stoch_K"
            @test names(res)[2] == "Stoch_D"
            @test Stoch(data_ts; n=25, k_smooth=4, d_smooth=5) isa TSFrame
            @test Stoch(data_ts; ma_type=:EMA) isa TSFrame
            @test Stoch(data_ts; ma_type=:SMMA) isa TSFrame
        end

        @testset "Williams R" begin
            @test WR(vec3) isa Matrix{Float64}
            res = WR(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "WR_raw"
            @test names(res)[2] == "WR_EMA"
            @test WR(data_ts; n=25) isa TSFrame
        end
    end
end
