# coding: utf-8



 def trav(start, goal, h, m) #駅から駅への最短経路。現在時刻とともに引数を渡す。メインディッシュとなる関数。
    start = self.convert(start) #現在地を路線と駅で示す
    goal = self.convert(goal) #目的地を路線と駅で示す
    @pq = PriorityQueue.new() #おもりつきグラフにおける優先度つき待ち行列
    @fmap = Array.new(@lines.length) #一つ前の乗り換え駅or出発駅
    for i in 0..@fmap.length-1
      @fmap[i] = Array.new(@lines[i].stations.length)
    end
    @pq.enq(NowPointTrans.new(start[0], start[1], h, m, 0)) #現在地
    d = nil
    while @pq.heapSize > 0
      d = @pq.deq()
      useUpTrain(d, goal, d.station)
      useDownTrain(d, goal, d.station)
      if @pq.record != nil && @pq.record < @pq.a[0]
        @pq.heapSize = 0
      end
    end
    if @fmap[goal[0]][goal[1]] != nil
      trace(goal, start)
    else
      print "本日中の電車はありません。"
    end
 end

   def useUpTrainTrans(point, goal, lowlim) #引数nowPointクラス、目的地の番地、最低電車に行って欲しい駅の下限
    if point.line == goal[0] && point.station == goal[1] && @pq.rewrite(point) == true
      @pq.record = point
      return true  #ここは、乗り換えたらそこが目的地だったような場合
    end
    s = @lines[point.line].stations[point.station] #現在いるStationの参照
    up = nil #乗る電車の情報
    i = 0 #point.h1時台の電車の発車時刻を順番に見ていく
    while i < s.boardUp[point.h1].length && up == nil
      if s.boardUp[point.h1][i][0] >= point.m1 && s.boardUp[point.h1][i][2] > lowlim
        up = [point.h1, s.boardUp[point.h1][i]]
      end
      i += 1
    end
    j = point.h1+1 #見つからなかったら次の電車を見つかるまで探す
    while up == nil
      if j >= s.boardUp.length
        return false
      else
        k = 0
        while k < s.boardUp[j].length && up == nil
          if s.boardUp[j][k][2] > lowlim
            up = [j, s.boardUp[j][k]] #boardUp[][]の中には、時刻（分）と発着駅の番地が入っている。
          end
          k += 1
        end
      end
      j += 1
    end #ここまでで電車が発見されている。その駅に電車が１本も通っていない可能性はここでは考慮しない。
    for i in point.station..up[1][2] #その電車の止まる全ての駅について
      t = @lines[point.line].time[i]-@lines[point.line].time[point.station] #その駅までにかかる時間
      if point.line == goal[0] && i == goal[1]    #その駅が目標の駅なら
        p = NowPointTrans.new(point.line, point.station, up[0], up[1][0], t, point.transTime+1) #出発駅→目標の駅のNowPoint
        p2 = NowPointTrans.new(goal[0], goal[1], p.h2, p.m2, transTime+1) #目標の駅のNowPoint
        if @pq.rewrite(p2) == true #このNowPointが早さ最高記録なら
          @fmap[point.line][i] = p
          @pq.record = p2 #塗り替え
        end
      elsif @lines[point.line].stations[i].trans.length != 0 #目標ではないが乗り換えられる
        p = NowPoint.new(point.line, point.station, up[0], up[1][0], tranTime+1, t) #出発駅→乗り換え駅のNowPoint
        if @fmap[point.line][i] == nil || @fmap[point.line][i].arriveSpeed > p.arriveSpeed #乗り換え駅の早さ最高記録なら
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1 #さらにその乗り換え先の駅について
            k = @lines[point.line].stations[i].trans[j] #乗り換え先の路線、駅、乗り換え所要時間の格納
            p2 = NowPoint.new(point.line, i, p.h2, p.m2, transTime+1, k[2]) #乗り換え駅→乗り換え先駅のNowPoint
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].arriveSpeed > p2.arriveSpeed #乗り換え先駅の早さ最高記録なら
              @fmap[k[0]][k[1]] = p2   #塗り替え
              @pq.enq(NowPoint.new(k[0], k[1], p2.h2, p2.m2, transTime+1)) #乗り換え先駅のNowPoint
            end
          end
        end
      end
    end
    if up[1][2] != @lines[point.line].size-1 #その線路の途中までしか行かない場合
      useUpTrain(NowPoint.new(point.line, point.station, up[0], up[1][0]+1, transTime), goal, up[1][2]) #次の電車も調べる
      #up[1][0]+1により60分となることがあるがそれはアルゴリズム上気にする必要ない
    end
    return true
  end

  def useDownTrain(point, goal, highlim, transTime) #逆方向への電車を探す
    if point.line == goal[0] && point.station == goal[1] && @pq.rewrite(point) == true
      @pq.record = point
      return true
    end
    s = @lines[point.line].stations[point.station]
    down = nil
    i = 0
    while i < s.boardDown[point.h1].length && down == nil
      if s.boardDown[point.h1][i][0] >= point.m1 && s.boardDown[point.h1][i][2] < highlim
        down = [point.h1, s.boardDown[point.h1][i]]
      end
      i += 1
    end
    j = point.h1+1
    while down == nil
      if j >= s.boardDown.length
        return false
      else
        k = 0
        while k < s.boardDown[j].length && down == nil
          if s.boardDown[j][k][2] < highlim
            down = [j, s.boardDown[j][k]]
          end
          k += 1
        end
      end
      j += 1
    end
    for i in down[1][2]..point.station
      t = @lines[point.line].time[point.station]-@lines[point.line].time[i]
      if point.line == goal[0] && i == goal[1]
        p = NowPoint.new(point.line, point.station, down[0], down[1][0], transTime+1, t)
        p2 = NowPoint.new(goal[0], goal[1], p.h2, p.m2, transTime+1)
        if @pq.rewrite(p2) == true
          @fmap[point.line][i] = p
          @pq.record = p2
        end
      elsif @lines[point.line].stations[i].trans.length != 0
        p = NowPoint.new(point.line, point.station, down[0], down[1][0], transTime+1, t)
        if @fmap[point.line][i] == nil || @fmap[point.line][i].arriveSpeed > p.arriveSpeed
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1
            k = @lines[point.line].stations[i].trans[j]
            p2 = NowPoint.new(point.line, i, p.h2, p.m2, transTime+1, k[2])
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].arriveSpeed > p2.arriveSpeed
              @fmap[k[0]][k[1]] = p2
              @pq.enq(NowPoint.new(k[0], k[1], p2.h2, p2.m2, transTime+1))
            end
          end
        end
      end
    end
    if down[1][2] != 0
      useDownTrain(NowPoint.new(point.line, point.station, down[0], down[1][0]+1, transTime), goal, down[1][2])
    end
    return true
  end

  def trace(start, goal) #引数はconvertされた後の番地の配列
    comments = ["到着です。\n"]
    while start != goal
      prev = @fmap[start[0]][start[1]] #NowPoint型の値。遡って一つ前の点を参照する。
      toline = @lines[start[0]].name
      tostation = @lines[start[0]].stations[start[1]].name
      fromline = @lines[prev.line].name
      fromstation = @lines[prev.line].stations[prev.station].name
      totime = prev.h2.to_s+"時"+prev.m2.to_s+"分"
      fromtime = prev.h1.to_s+"時"+prev.m1.to_s+"分"
      if start[0] == prev.line #同じ路線の駅、すなわち電車での移動
        if start[1] < prev.station
          direction = @lines[start[0]].stations[0].name #どちら方面の電車か
        else
          direction = @lines[start[0]].stations[@lines[start[0]].size-1].name
        end
        comments.push(tostation+"駅に"+totime+"に着きます。\n")
        comments.push(fromline+fromstation+"駅を"+direction+"方面の"+fromtime+"発の電車で出発します。\n")
      else      #徒歩での移動
        comments.push(toline+tostation+"駅に"+totime+"に着きます。\n")
        comments.push(fromline+fromstation+"駅から"+fromtime+"に歩き始めます。\n")
      end
      start = [prev.line, prev.station]
    end
    for i in 0..comments.length-1
      j = comments.length-1-i
      print comments[j]
    end
    return nil
  end

  def travBack(start, goal, h, m) #到着時刻を指定するバージョン。
    sStart = start
    sGoal = goal  #のちのtravで使うためにconvertする前の状態のものを保存
    start = self.convert(start)
    goal = self.convert(goal)
    @pq = PriorityQueue.new()
    @fmap = Array.new(@lines.length)
    for i in 0..@fmap.length-1
      @fmap[i] = Array.new(@lines[i].stations.length)
    end
    @pq.enq(BackNowPoint.new(goal[0], goal[1], h, m))
    d = nil
    while @pq.heapSize > 0
      d = @pq.deq()
      backUpTrain(d, start, d.station)
      backDownTrain(d, start, d.station)
      if @pq.record != nil && @pq.record < @pq.a[0]
        @pq.heapSize = 0
      end
    end
    if fmap[start[0]][start[1]] != nil
      trav(sStart, sGoal, @fmap[start[0]][start[1]].h1, @fmap[start[0]][start[1]].m1)
    else
      print "当日中の出発ではその時間には着けません。"
    end
  end

  def backUpTrain(point, start, highlim)
    if point.line == start[0] && point.station == start[1] && @pq.rewrite(point) == true
      @pq.record = point
      return true
    end
    s = @lines[point.line].stations[point.station]
    up = nil
    i = s.boardUp[point.h1].length-1
    while i >= 0 && up == nil
      if s.boardUp[point.h1][i][0] <= point.m1 && s.boardUp[point.h1][i][1] < highlim
        up = [point.h1, s.boardUp[point.h1][i]]
      end
      i -= 1
    end
    j = point.h1-1
    while up == nil
      if j < 0
        return false
      else
        k = s.boardUp[j].length-1
        while k >= 0 && up == nil
          if s.boardUp[j][k][1] < highlim
            up = [j, s.boardUp[j][k]] #目標とする駅の到着時刻と乗る電車の発着駅
          end
          k -= 1
        end
      end
      j -= 1
    end
    for i in up[1][1]..point.station
      t = @lines[point.line].time[point.station]-@lines[point.line].time[i] #正の値。遡る時間。
      if point.line == start[0] && i == start[1]
        p = BackNowPoint.new(point.line, point.station, up[0], up[1][0], t) #到着駅→出発駅のBackNowPoint
        p2 = BackNowPoint.new(start[0], start[1], p.h2, p.m2) #出発駅のBackNowPoint
        if @pq.rewrite(p2) == true
          @fmap[point.line][i] = p
          @pq.record = p2
        end
      elsif @lines[point.line].stations[i].trans.length != 0
        p = BackNowPoint.new(point.line, point.station, up[0], up[1][0], t) #到着駅→乗り換え駅のBackNowPoint
        if @fmap[point.line][i] == nil || @fmap[point.line][i].leaveSpeed < p.leaveSpeed
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1
            k = @lines[point.line].stations[i].trans[j]
            p2 = BackNowPoint.new(point.line, i, p.h2, p.m2, k[2])
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].leaveSpeed < p2.leaveSpeed
              @fmap[k[0]][k[1]] = p2
              @pq.enq(BackNowPoint.new(k[0], k[1], p2.h2, p2.m2))
            end
          end
        end
      end
    end
    if up[1][1] != 0
      backUpTrain(NowPoint.new(point.line, point.station, up[0],up[1][0]-1), start, up[1][1])
    end
  end

  def backDownTrain(point, start, lowlim)
    if point.line == start[0] && point.station == start[1] && @pq.rewrite(point) == true
      @pq.record = point
      return true
    end
    s = @lines[point.line].stations[point.station]
    down = nil
    i = s.boardDown[point.h1].length-1
    while i >= 0 && down == nil
      if s.boardDown[point.h1][i][0] <= point.m1 && s.boardDown[point.h1][i][1] > lowlim
        down = [point.h1, s.boardDown[point.h1][i]]
      end
      i -= 1
    end
    j = point.h1-1
    while down == nil
      if j < 0
        return false
      else
        k = s.boardDown[j].length-1
        while k>=0 && down == nil
          if s.boardDown[j][k][1] > lowlim
            down = [j, s.boardDown[j][k]]
          end
          k -= 1
        end
      end
      j -= 1
    end
    for i in point.station..down[1][1]
      t = @lines[point.line].time[i]-@lines[point.line].time[point.station]
      if point.line == start[0] && i == start[1]
        p = BackNowPoint.new(point.line, point.station, down[0], down[1][0], t)
        p2 = BackNowPoint.new(start[0], start[1], p.h2, p.m2)
        if @pq.rewrite(p2) == true
          @fmap[point.line][i] = p
          @pq.record = p2
        end
      elsif @lines[point.line].stations[i].trans.length != 0
        p = BackNowPoint.new(point.line, point.station, down[0], down[1][0], t)
        if @fmap[point.line][i] == nil || @fmap[point.line][i].leaveSpeed < p.leaveSpeed
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1
            k = @lines[point.line].stations[i].trans[j]
            p2 = BackNowPoint.new(point.line, i, p.h2, p.m2, k[2])
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].leaveSpeed < p2.leaveSpeed
              @fmap[k[0]][k[1]] = p2
              @pq.enq(BackNowPoint.new(k[0], k[1], p2.h2, p2.m2))
            end
          end
        end
      end
    end
    if down[1][1] != @lines[point.line].size-1
      backDownTrain(NowPoint.new(point.line, point.station, down[0], down[1][0]-1), start, down[1][1])
    end
  end
end

class NowPointTrans #現在地と現在時刻をセットで収納。
  attr_accessor :line, :station, :h1, :m1, :h2, :m2, :arriveSpeed, :transTime
  def initialize(line, station, h, m, transTime, t=nil)
    @line = line
    @station = station
    @h1 = h
    @m1 = m  #そこから出発する時刻
    @transTime = trans
    if t != nil
      @h2 = @h1+t/60
      @m2 = @m1+t%60
      if @m2 > 60
        @h2 += 1
        @m2 -= 60 #そこから次に降りる駅に到着する時刻
      end
      @arriveSpeed = (@transTime*10000)+@h2*60+@m2 #到着時刻の早さ。ただしTransTimeを優先的に考える。
    else
      @h2 = nil
      @m2 = nil
    end
  end

  #出発時刻の早さは以下のメソッドで定義。Heapクラスの計算でも利用。
  def <(other)
    if @transTime == other.transTime
      return @h1 * 60 + @m1 < other.h1 * 60 + other.m1
    else
      return @transTime < other.transTime
    end
  end
  def >(other)
    if @transTime == other.transTime
      return @h1 * 60 + @m1 > other.h1 * 60 + other.m1
    else
      return @transTime > other.transTime
    end
  end
  def ==(other)
    if other == nil
      return false
    else
      return @transTime == other.transTime && @h1 * 60 + @m1 == other.h1 * 60 + other.m1
    end
  end
end


class BackNowPoint #travBackで利用
  attr_accessor :line, :station, :h1, :m1, :h2, :m2, :leaveSpeed
  def initialize(line, station, h, m, t=nil)
    @line = line
    @station = station
    @h1 = h
    @m1 = m #到着時刻
    if t != nil
      @h2 = @h1-t/60
      @m2 = @m1-t%60
      if @m2 < 0
        @h2 -= 1
        @m2 += 60
      end
      @leaveSpeed = @h2*60+@m2 #出発時刻の早さ。遅い方が良い。
    else
      @h2 = nil
      @m2 = nil
    end
  end

  def <(other) #同じHeap木を使いたいので、符号をここで反転させておく。
    return @h1 * 60 + @m1 > other.h1 * 60 + other.m1
  end
  def >(other)
    return @h1 * 60 + @m1 < other.h1 * 60 + other.m1
  end
  def ==(other)
    if other == nil
      return false
    else
      return @h1 * 60 + @m1 == other.h1 * 60 + other.m1
    end
  end
end












def traceTrans(start, goal) #引数はconvertされた後の番地の配列
    comments = ["到着です。\n"]
    while start != goal
      prev = @fmap[start[0]][start[1]] #NowPointTrans型の値。遡って一つ前の点を参照する。
      toline = @lines[start[0]].name
      tostation = @lines[start[0]].stations[start[1]].name
      fromline = @lines[prev.line].name
      fromstation = @lines[prev.line].stations[prev.station].name
      totime = prev.h2.to_s+"時"+prev.m2.to_s+"分"
      fromtime = prev.h1.to_s+"時"+prev.m1.to_s+"分"
      if start[0] == prev.line #同じ路線の駅、すなわち電車での移動
        if start[1] < prev.station
          direction = @lines[start[0]].stations[0].name #どちら方面の電車か
        else
          direction = @lines[start[0]].stations[@lines[start[0]].size-1].name
        end
        comments.push(tostation+"駅に"+totime+"に着きます。\n")
        comments.push(fromline+fromstation+"駅を"+direction+"方面の"+fromtime+"発の電車で出発します。\n")
      else      #徒歩での移動
        comments.push(toline+tostation+"駅に"+totime+"に着きます。\n")
        comments.push(fromline+fromstation+"駅から"+fromtime+"に歩き始めます。\n")
      end
      start = [prev.line, prev.station]
    end
    t = @fmap[start[0]][start[1]].transTime
    if t != 0
      t -= 1
    end
    comments.push(t.to_s+"回乗り換えです。\n")
    for i in 0..comments.length-1
      j = comments.length-1-i
      print comments[j]
    end
    return nil
  end




















  def travBackTransTime(start, goal, h, m) #到着時刻を指定するバージョン。
    sStart = start
    sGoal = goal  #のちのtravで使うためにconvertする前の状態のものを保存
    start = self.convert(start)
    goal = self.convert(goal)
    @pq = PriorityQueue.new()
    @fmap = Array.new(@lines.length)
    for i in 0..@fmap.length-1
      @fmap[i] = Array.new(@lines[i].stations.length)
    end
    @pq.enq(BackNowPoint.new(goal[0], goal[1], h, m))
    d = nil
    while @pq.heapSize > 0
      d = @pq.deq()
      backUpTrain(d, start, d.station)
      backDownTrain(d, start, d.station)
      if @pq.record != nil && @pq.record < @pq.a[0]
        @pq.heapSize = 0
      end
    end
    if fmap[start[0]][start[1]] != nil
      trav(sStart, sGoal, @fmap[start[0]][start[1]].h1, @fmap[start[0]][start[1]].m1)
    else
      print "当日中の出発ではその時間には着けません。"
    end
  end

  def backUpTrain(point, start, highlim)
    if point.line == start[0] && point.station == start[1] && @pq.rewrite(point) == true
      @pq.record = point
      return true
    end
    s = @lines[point.line].stations[point.station]
    up = nil
    i = s.boardUp[point.h1].length-1
    while i >= 0 && up == nil
      if s.boardUp[point.h1][i][0] <= point.m1 && s.boardUp[point.h1][i][1] < highlim
        up = [point.h1, s.boardUp[point.h1][i]]
      end
      i -= 1
    end
    j = point.h1-1
    while up == nil
      if j < 0
        return false
      else
        k = s.boardUp[j].length-1
        while k >= 0 && up == nil
          if s.boardUp[j][k][1] < highlim
            up = [j, s.boardUp[j][k]] #目標とする駅の到着時刻と乗る電車の発着駅
          end
          k -= 1
        end
      end
      j -= 1
    end
    for i in up[1][1]..point.station
      t = @lines[point.line].time[point.station]-@lines[point.line].time[i] #正の値。遡る時間。
      if point.line == start[0] && i == start[1]
        p = BackNowPoint.new(point.line, point.station, up[0], up[1][0], t) #到着駅→出発駅のBackNowPoint
        p2 = BackNowPoint.new(start[0], start[1], p.h2, p.m2) #出発駅のBackNowPoint
        if @pq.rewrite(p2) == true
          @fmap[point.line][i] = p
          @pq.record = p2
        end
      elsif @lines[point.line].stations[i].trans.length != 0
        p = BackNowPoint.new(point.line, point.station, up[0], up[1][0], t) #到着駅→乗り換え駅のBackNowPoint
        if @fmap[point.line][i] == nil || @fmap[point.line][i].leaveSpeed < p.leaveSpeed
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1
            k = @lines[point.line].stations[i].trans[j]
            p2 = BackNowPoint.new(point.line, i, p.h2, p.m2, k[2])
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].leaveSpeed < p2.leaveSpeed
              @fmap[k[0]][k[1]] = p2
              @pq.enq(BackNowPoint.new(k[0], k[1], p2.h2, p2.m2))
            end
          end
        end
      end
    end
    if up[1][1] != 0
      backUpTrain(NowPoint.new(point.line, point.station, up[0],up[1][0]-1), start, up[1][1])
    end
  end

  def backDownTrain(point, start, lowlim)
    if point.line == start[0] && point.station == start[1] && @pq.rewrite(point) == true
      @pq.record = point
      return true
    end
    s = @lines[point.line].stations[point.station]
    down = nil
    i = s.boardDown[point.h1].length-1
    while i >= 0 && down == nil
      if s.boardDown[point.h1][i][0] <= point.m1 && s.boardDown[point.h1][i][1] > lowlim
        down = [point.h1, s.boardDown[point.h1][i]]
      end
      i -= 1
    end
    j = point.h1-1
    while down == nil
      if j < 0
        return false
      else
        k = s.boardDown[j].length-1
        while k>=0 && down == nil
          if s.boardDown[j][k][1] > lowlim
            down = [j, s.boardDown[j][k]]
          end
          k -= 1
        end
      end
      j -= 1
    end
    for i in point.station..down[1][1]
      t = @lines[point.line].time[i]-@lines[point.line].time[point.station]
      if point.line == start[0] && i == start[1]
        p = BackNowPoint.new(point.line, point.station, down[0], down[1][0], t)
        p2 = BackNowPoint.new(start[0], start[1], p.h2, p.m2)
        if @pq.rewrite(p2) == true
          @fmap[point.line][i] = p
          @pq.record = p2
        end
      elsif @lines[point.line].stations[i].trans.length != 0
        p = BackNowPoint.new(point.line, point.station, down[0], down[1][0], t)
        if @fmap[point.line][i] == nil || @fmap[point.line][i].leaveSpeed < p.leaveSpeed
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1
            k = @lines[point.line].stations[i].trans[j]
            p2 = BackNowPoint.new(point.line, i, p.h2, p.m2, k[2])
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].leaveSpeed < p2.leaveSpeed
              @fmap[k[0]][k[1]] = p2
              @pq.enq(BackNowPoint.new(k[0], k[1], p2.h2, p2.m2))
            end
          end
        end
      end
    end
    if down[1][1] != @lines[point.line].size-1
      backDownTrain(NowPoint.new(point.line, point.station, down[0], down[1][0]-1), start, down[1][1])
    end
  end
