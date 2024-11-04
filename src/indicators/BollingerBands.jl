"""
このコードでは以下のような工夫をしています：

1. 二乗和（sum_sq）を保持することで、標準偏差の計算を効率化
   - 従来の方法: 各要素と平均の差の二乗を毎回計算
   - 改善後: 二乗和を使って分散を計算 `Var(X) = E(X^2) - (E(X))^2`

2. メモリ効率
   - 循環バッファを使用して過去の値を保持
   - 必要最小限のデータ（合計値と二乗和）のみを更新

3. 計算量の削減
   - 新しい値が入る時に O(1) で更新可能
   - 毎回全データを走査する必要がない

使用例：
```python
# サンプルデータ
data = [10, 12, 14, 13, 15, 16, 15, 14, 13, 12]

bands = calculate_bollinger_bands(data, period=5, num_std=2)
for i, (lower, mean, upper) in enumerate(bands):
    if mean is not None:
        print(f"データ{i}: 下限={lower:.2f}, 平均={mean:.2f}, 上限={upper:.2f}")
```

このアプローチにより、計算量を O(n) から O(1) に削減できます。また、メモリ使用量も一定に保たれます。

ボリンジャーバンドの計算に特化した実装が必要な場合や、他の統計値も計算したい場合は、コードを調整することができます。何か具体的なニーズはありますか？



```julia
function rolling_std(data::Vector{T}, period::Int) where T
    buf = CircBuff{T}(period)
    results = zeros(T, length(data))
    sum_x = zero(T)    # Running sum for mean calculation
    sum_x2 = zero(T)   # Running sum of squares

    @inbounds for (i, x) in enumerate(data)
        if i > period
            # Update running sums by removing oldest value and adding new value
            old_x = first(buf)
            sum_x = sum_x - old_x + x
            sum_x2 = sum_x2 - old_x^2 + x^2

            # Calculate variance using the relationship: Var(X) = E(X^2) - (E(X))^2
            mean = sum_x / period
            variance = (sum_x2 / period) - mean^2

            # Handle potential floating-point errors that might result in small negative variance
            results[i] = sqrt(max(zero(T), variance))
            push!(buf, x)
        else
            push!(buf, x)
            sum_x += x
            sum_x2 += x^2

            # Calculate for partial window
            n = length(buf)
            if n > 1  # Need at least 2 points for standard deviation
                mean = sum_x / n
                variance = (sum_x2 / n) - mean^2
                results[i] = sqrt(max(zero(T), variance))
            else
                results[i] = zero(T)
            end
        end
    end
    return results
end

```

このコードの特徴は以下の通りです：

1. 既存のSMAと同様のパターンで、循環バッファを使用
2. 分散計算の公式 `Var(X) = E(X²) - (E(X))²` を利用して計算量を削減
3. 浮動小数点演算の誤差を考慮して、分散が負にならないよう`max(zero(T), variance)`を使用
4. ジェネリックな型パラメータ`T`を使用して、異なる数値型に対応
5. `@inbounds`マクロを使用してバウンズチェックを省略し、パフォーマンスを最適化

これを元のSMAと組み合わせることで、ボリンジャーバンドの計算が可能です。さらなる最適化や修正が必要な場合は、お知らせください。
"""

function BB(ts::TSFrame, period::Int = 14; field::Symbol = :Close, ma_type::Symbol = :SMA, num_std = 2)
	prices = ts[:, field]
    if ma_type == :SMA
        results = BB(prices, period; num_std = num_std)
    end
	colnames = [:BB_Center, :BB_Upper, :BB_Lower]
	return TSFrame(results, index(ts), colnames = colnames)
end
export BB

@inline Base.@propagate_inbounds function BB(prices::Vector{T}, period::Int = 14; num_std::Int = 2) where T
    buf = CircBuff{T}(period)
    results = zeros(T, (length(prices),3))
    running_sum = zero(T)
    running_sum_x2 = zero(T)
    @inbounds for (i, price) in enumerate(prices)
        if i > period
            out = first(buf)
            running_sum = running_sum - out + price
            running_sum_x2 = running_sum_x2 - out^2 + price^2
            mean = running_sum / period
            variance = running_sum_x2 / period - mean^2
            std = sqrt(max(zero(T), variance))
            results[i,1] =  mean
            results[i,2] =  mean + num_std * std
            results[i,3] =  mean - num_std * std
            push!(buf, price)
        else
            push!(buf, price)
            running_sum += price
            running_sum_x2 += price^2
            mean = running_sum / i
            variance = running_sum_x2 / i - mean^2
            std = sqrt(max(zero(T), variance))
            results[i,1] =  mean
            results[i,2] =  mean + num_std * std
            results[i,3] =  mean - num_std * std
        end
    end
    return results
end