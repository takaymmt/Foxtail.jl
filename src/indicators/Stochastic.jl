function Stoch(ts::TSFrame, period::Int=14; field::Vector{Symbol}=[:High, :Low, :Close], ma_type::Symbol=:SMA)
    prices = ts[:,field] |> Matrix
    results = Stoch(prices; period=period, ma_type=ma_type)
    colnames = [:Stoch_K, :Stoch_D]
    return TSFrame(results, index(ts), colnames=colnames)
end
export Stoch

"""
@btime Stoch(aapl)
  699.625 μs (44428 allocations: 6.25 MiB)
11063×2 TSFrame with Date Index

時系列データのrolling window内での最大値・最小値を効率的に計算する方策について、いくつかのアプローチを検討しましょう。

1. モノトーンキューを使用するアプローチ
   - 二重末尾キュー(deque)を使用し、最大値用と最小値用の2つのキューを維持
   - キューには(値, インデックス)のペアを格納
   - 特徴:
     - キュー内の値は単調減少（最大値用）または単調増加（最小値用）を保持
     - window範囲外の古いデータは自動的に削除
     - 各要素についての操作がO(1)の償却計算量で済む
   - メリット: 比較回数が大幅に削減される
   - デメリット: 追加のメモリが必要

2. セグメント木を使用するアプローチ
   - 完全二分木構造で区間の最大値・最小値を管理
   - 特徴:
     - 各ノードが区間の最大値と最小値を保持
     - クエリ時間はO(log n)
     - 更新も O(log n)
   - メリット: 任意の区間のクエリに対応可能
   - デメリット: 固定長windowには少しオーバースペック

3. 循環バッファベースのアプローチ（既存の実装を活用）
   - 循環バッファに加えて補助的なデータ構造を使用
   - 特徴:
     - 現在のwindow内の最大値・最小値に加えて、第二最大値・第二最小値も保持
     - 値が出ていくときに最大値・最小値が更新される場合のみ、window内を再スキャン
   - メリット: 既存の循環バッファ実装を活用できる
   - デメリット: 最悪ケースでwindow幅分の走査が必要

4. スパーステーブルアプローチ
   - 前処理でO(n log n)の時間をかけて、様々な長さの区間の最大値・最小値を計算
   - 特徴:
     - クエリ時間がO(1)
     - 固定長windowの場合は効率的
   - メリット: 高速なクエリ
   - デメリット: 前処理のコストが高い

Julia特有の最適化の可能性：
- `SlidingWindows.jl`パッケージの利用
- SIMD操作の活用による並列化
- `CircularBuffer`型（DataStructures.jl）との組み合わせ

推奨アプローチ：
上記の中で、与えられた問題設定（固定長window）に最も適していると考えられるのは「モノトーンキューアプローチ」です。理由は：
1. 実装が比較的シンプル
2. 各要素に対する操作が償却O(1)
3. メモリ使用量が適度（window幅に比例）
4. 最大値と最小値の両方を効率的に追跡可能

このアプローチを採用する場合、Juliaの`DataStructures.jl`パッケージの`Deque`型を利用できます。

実装に進む前に、これらのアプローチについて詳しく知りたい部分や、特定のアプローチについての具体的な質問はありますか？
---
モノトーンキューアプローチをベースに、循環Dequeを活用した最適化案を詳しく説明します。

最適化アプローチの詳細：

1. データ構造
   - 既存の循環バッファを循環Dequeに拡張して基本データを保持
   - 最大値追跡用と最小値追跡用の2つの循環Dequeを追加
   - 各Dequeには(値, インデックス)のペアを格納

2. アルゴリズムの動作
   - 新しい値の追加時：
     * 最大値Dequeの末尾から、新しい値より小さい値を全て削除
     * 最小値Dequeの末尾から、新しい値より大きい値を全て削除
     * 新しい値とそのインデックスを各Dequeに追加
   - window外の値の削除：
     * 各Dequeの先頭のインデックスをチェック
     * window範囲外になった値を自動的に削除

3. 最適化のポイント
   - メモリ効率：
     * 循環Dequeの特性を活かし、物理的なメモリ移動を最小化
     * インデックスの循環的な扱いにより、メモリ再割り当てを回避

   - 計算効率：
     * 各要素は最大1回しかDequeに追加されない
     * 各要素は最大1回しかDequeから削除されない
     * window内の値の比較回数が最小限に抑えられる

4. 性能特性
   - 時間計算量：
     * 要素の追加・削除：償却O(1)
     * 最大値・最小値の取得：O(1)
   - 空間計算量：
     * 追加のメモリ使用量：O(w)（wはwindow幅）
     * 元のデータ用の循環バッファ：O(n)

5. 主なメリット
   - 比較回数の大幅な削減
   - メモリアクセスの局所性が高い
   - キャッシュ効率が良い
   - 実装が比較的シンプル

6. 特殊ケースの処理
   - 開始時（要素数がw未満の場合）：
     * 通常の処理と同じロジックで対応可能
     * 特別な分岐処理が不要

7. 注意点
   - 同値の要素が存在する場合：
     * Dequeから値を削除する際に、インデックスの厳密なチェックが必要
     * 同値要素の処理を正確に行うために、インデックス比較を含める

この手法の利点：
1. 既存の循環バッファ実装を拡張できる
2. メモリアロケーションを最小限に抑えられる
3. キャッシュ効率が良い
4. 実装が比較的単純で保守性が高い

これを基に実装を進める場合、Juliaの型システムを活用して、ジェネリックな実装にすることで、様々なデータ型に対応できます。実装に進みましょうか？
"""

@inline Base.@propagate_inbounds function Stoch(prices::Matrix{Float64};
    period::Int=14,
    k_smooth::Int=3,
    d_smooth::Int=3,
    ma_type::Symbol=:SMA)

    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [high low close]"))
    end

    if period < 1 || k_smooth < 1 || d_smooth < 1
        throw(ArgumentError("periods must be positive"))
    end

    n = size(prices, 1)
    if n < period
        throw(ArgumentError("price series length must be greater than period"))
    end

    # Extract price data
    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]

    # Pre-allocate arrays
    raw_k = zeros(n)
    slow_k = zeros(n)
    slow_d = zeros(n)

    # Calculate Raw %K
    @inbounds for i in period:n
        window_high = maximum(highs[i-period+1:i])
        window_low = minimum(lows[i-period+1:i])

        denominator = window_high - window_low

        if denominator ≈ 0.0
            raw_k[i] = 50.0  # Default to middle value when price range is zero
        else
            raw_k[i] = 100.0 * (closes[i] - window_low) / denominator
        end
    end

    # Apply first smoothing to get Slow %K
    if ma_type == :SMA
        slow_k = SMA(raw_k, k_smooth)
    elseif ma_type == :EMA
        slow_k = EMA(raw_k, k_smooth)
    elseif ma_type == :SMMA || ma_type == :RMA
        slow_k = SMMA(raw_k, k_smooth)
    else
        throw(ArgumentError("ma_type must be one of: :SMA, :EMA, :SMMA"))
    end

    # Calculate %D by smoothing Slow %K
    if ma_type == :SMA
        slow_d = SMA(slow_k, d_smooth)
    elseif ma_type == :EMA
        slow_d = EMA(slow_k, d_smooth)
    elseif ma_type == :SMMA || ma_type == :RMA
        slow_d = SMMA(slow_k, d_smooth)
    end

    # Handle initial NaN values
    @inbounds for i in 1:period-1
        slow_k[i] = NaN
        slow_d[i] = NaN
    end

    # Return matrix with Slow %K and %D
    return hcat(slow_k, slow_d)
end