# coding: utf-8
#610185E 川島拓海
#最終課題


class Station
  attr_accessor :name, :number, :boardUp, :boardDown, :trans
  def initialize(name, line, number)
    @name = name
    @line = line #所属する路線。Lineクラスのオブジェクト。
    @number = number
    @boardUp = Array.new(25) #0時台から24時台(翌日)まで
    @boardDown = Array.new(25)
    for i in 0..24
      @boardUp[i] = Array.new()
      @boardDown[i] = Array.new() #時刻表。LineクラスでTrainQueueを元に登録される。
    end
    @trans = Array.new() #乗り換え可能駅と乗り換え時間
  end

  def showBoard()
    print @line.stations[@line.size-1].name,"行き\n"
    for i in 0..@boardUp.length-1
      print i,"   "
      for j in 0..@boardUp[i].length-1
        if @number-@line.first != @boardUp[i][j][2] #当駅着でない
          print " ",@boardUp[i][j][0]
          if @number-@line.first == @boardUp[i][j][1] #当駅発 
            print "★"
          end
          if @boardUp[i][j][2] != @line.size-1 #路線の最後までいかない
            print "(",@line.stations[@boardUp[i][j][2]].name,")"
          end
        end
      end
      print "\n"
    end
    print "\n",@line.stations[0].name,"行き\n"
    for i in 0..@boardDown.length-1
      print i,"   "
      for j in 0..@boardDown[i].length-1
        if @number-@line.first != @boardDown[i][j][2]
          print " ",@boardDown[i][j][0]
          if @number-@line.first == @boardDown[i][j][1]
            print "★"
          end
          if @boardDown[i][j][2] != 0
            print "(",@line.stations[@boardDown[i][j][2]].name,")"
          end
        end
      end
      print "\n"
    end
    print "★は当駅発\n"
    return nil
  end
end




class TrainQueue
  attr_accessor :tUp, :tDown
  def initialize(lineID, line)
    @line = line
    ftrain = lineID+"Train"
    f = open(ftrain)
    @tUp = Array.new()
    @tDown = Array.new()
    while s=f.gets
      start, stop, h, m = s.split(/ /)
      start = start.to_i
      stop = stop.to_i
      if start<stop
        @tUp.push(Train.new(start, stop, h.to_i, m.to_i, @line))
      elsif start>stop
        @tDown.push(Train.new(start, stop, h.to_i, m.to_i, @line))
      end
    end
    f.close
    mergesort(@tUp)
    mergesort(@tDown) #併合整列法の利用
  end

  def add(train) #新しい電車をダイヤに追加したい。引数はTrainクラス。
    if train.start < train.stop
      i = 0
      while i < @tUp.length && train > tUp[i]
        i += 1
      end
      if i>=0 && train.speed-@tUp[i-1].speed <= 2
        return false
      end
      if i<@tUp.length && train.speed-@tUp[i].speed >= -2
        return false #他の電車との間隔が近すぎたらやめる。
      end
      @tUp.insert(i,train) #大丈夫そうならここで初めてinsert。
      return true
    elsif train.start > train.stop
      while i < @tDown.length && train > tUp[i]
        i += 1
      end
      if i>=0 && train.speed-@tDown[i-1].speed <= 2
        return false
      end
      if i<@tDown.length && train.speed-@tDown[i].speed >= -2
        return false #他の電車との間隔が近すぎたらやめる。
      end
      @tDown.insert(i,train)
      return true
    else
      return false
    end
  end
end


def mergesort(a)
  mergesortSub(a,0,a.length)
end

def mergesortSub(a,l,r)
  if r>l+1
    m=(l+r)/2
    mergesortSub(a,l,m)
    mergesortSub(a,m,r)
    merge2(a,l,m,r)
  end
  a
end

def merge2(a,l,m,r)
  c=Array.new(r-l)
  ia=l
  ib=m
  for i in 0..c.length-1
    if ia>=m
      c[i]=a[ib]
      ib=ib+1
    elsif ib>=r
      c[i]=a[ia]
      ia=ia+1
    elsif a[ia]<a[ib]
      c[i]=a[ia]
      ia=ia+1
    else
      c[i]=a[ib]
      ib=ib+1
    end
  end
  for i in 0..c.length-1
    a[l+i]=c[i]
  end
end



class Train
  attr_accessor :start, :stop, :h, :m, :speed
  def initialize(start, stop, h, m, line)
    @start = start
    @stop = stop
    @h = h
    @m = m
    @line = line
    if @start < @stop
      @speed = h*60+m-@line.time[start-@line.first]
    #仮想で何時に路線0番目の駅を出るか
    elsif @start > @stop
      @speed = h*60+m+@line.time[start-@line.first]
      #仮想で何時に路線0番目の駅に着くか
    end
  end

  def <(other)
    return @speed<other.speed
  end
  def >(other)
    return @speed>other.speed
  end
  def ==(other)
    return @speed==other.speed
  end
end



class Line
  attr_accessor :name, :id, :stations, :time, :first, :size, :trains
  def initialize(fname, graph=nil) #graphも
    @graph = graph
    f = open(fname)
    @name = f.gets.chomp #路線名
    @id = f.gets.chomp #路線記号
    n,s = f.gets.split(/ /)
    s = s.chomp()
    n = n.to_i
    @stations = [Station.new(s, self, n)]
    @first = n   #最初の駅の番号。駅の番号を配列内の番地に直す際に使用。
    @size = 1    #駅の数
    @time = [0]  #始発駅からかかる時間
    while x = f.gets
      s,t = x.split(/ /)
      n = n+1 #駅の番号
      @stations.push(Station.new(s, self, n))
      connect(t.to_i)
      @size += 1
    end
    f.close
    @trains = TrainQueue.new(@id, self)
    for i in 0..@trains.tUp.length-1  #全ての電車について  
      aStart = @trains.tUp[i].start-@first
      aStop = @trains.tUp[i].stop-@first #発着駅を配列内の番地に直す               
      for j in aStart..aStop #その電車の止まる全ての駅について
        minutes = @time[j]-@time[aStart] #かかる時間(分)
        h = @trains.tUp[i].h + (@trains.tUp[i].m+minutes)/60 #到着時刻(時)
        m = (@trains.tUp[i].m+minutes)%60                      #時刻(分)
        @stations[j].boardUp[h].push([m, aStart, aStop]) #時刻、発着駅の番地を格納
      end
    end
    for i in 0..@trains.tDown.length-1 #逆も同様        
      aStart = @trains.tDown[i].start-@stations[0].number
      aStop = @trains.tDown[i].stop-@stations[0].number
      for j in aStop..aStart
        minutes = @time[aStart]-@time[j]
        h = @trains.tDown[i].h + (@trains.tDown[i].m+minutes)/60
        m = (@trains.tDown[i].m+minutes)%60
        @stations[j].boardDown[h].push([m, aStart, aStop])
      end
    end
  end

  def connect(t)
    @time.push(t)
  end

  def stationsShow()
    for i in 0..@stations.length-1
      print @id,@stations[i].number," ",@stations[i].name
      s = @stations[i].trans
      if s.length != 0 #乗り換え駅があれば
        print "(乗り換え"
        for j in 0..s.length-1
          print " ",@graph.lines[s[j][0]].name,@graph.lines[s[j][0]].stations[s[j][1]].name
        end
        print ")"
      end
      print "\n"
    end
  end
end





class LineGraph
  def initialize(fnames, ftrans)  #路線名の配列と乗り換えのファイルを渡す
    @lines = Array.new()
    for i in 0..fnames.length-1
      @lines.push(Line.new(fnames[i], self))
    end
    f = open(ftrans)
    while x = f.gets
      s1, s2, t = x.split(/ /)
      connectTrans(s1, s2, t)
    end
    f.close
  end

  def connectTrans(s1, s2, t) #乗り換え可能な駅のセット
    p,a = self.convert(s1) #路線と駅を番号で登録
    q,b = self.convert(s2)
    if p == false || q == false #路線もしくは駅が存在しなかった場合
      return false
    end
    @lines[p].stations[a].trans.push([q, b, t.to_i])
    @lines[q].stations[b].trans.push([p, a, t.to_i]) #駅の情報に登録
    #Stationクラスのtransには乗り換え先の路線、駅、乗り換え所要時間を配列で入れる
  end

  def convert(spot) #路線のIDと駅番号を@linesの配列と@stationsの配列の番地にして返す
    id = spot[0]
    number = spot[1..(spot.length-1)].to_i
    for i in 0..@lines.length-1
      if @lines[i].id == id
        number = number-@lines[i].first #配列内の番号に直す
        if number < 0 || number >= @lines[i].size
          return false #駅がない
        end
        return [i, number]
      end
    end
    return false #路線がない
  end

  def trav(start, goal, h, m) #駅から駅への最短経路。現在時刻とともに引数を渡す。メインディッシュとなる関数。
    start = self.convert(start) #現在地を路線と駅で示す
    goal = self.convert(goal) #目的地を路線と駅で示す
    @pq = PriorityQueue.new() #おもりつきグラフにおける優先度つき待ち行列
    @fmap = Array.new(@lines.length) #一つ前の乗り換え駅or出発駅
    for i in 0..@fmap.length-1
      @fmap[i] = Array.new(@lines[i].stations.length)
    end
    @pq.enq(NowPoint.new(start[0], start[1], h, m)) #現在地
    d = nil
    while @pq.heapSize > 0
      d = @pq.deq()
      useUpTrain(d, goal, d.station)
      useDownTrain(d, goal, d.station)
      if @pq.record != nil && @pq.record < @pq.a[0]
        @pq.heapSize = 0
      end
    end
    if @fmap[goal[0]][goal[1]] != nil || start == goal
      trace(goal, start)
    else
      print "本日中の電車はありません。"
    end
  end

  def useUpTrain(point, goal, lowlim) #引数nowPointクラス、目的地の番地、最低電車に行って欲しい駅の下限
    if point.line == goal[0] && point.station == goal[1] && @pq.rewrite(point) == true
      @pq.record = point
      return true  #ここは、いきなりそこが目的地だったような場合
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
        p = NowPoint.new(point.line, point.station, up[0], up[1][0], t) #出発駅→目標の駅のNowPoint
        p2 = NowPoint.new(goal[0], goal[1], p.h2, p.m2) #目標の駅のNowPoint
        if @pq.rewrite(p2) == true #このNowPointが早さ最高記録なら
          @fmap[point.line][i] = p
          @pq.record = p2 #塗り替え
        end
      elsif @lines[point.line].stations[i].trans.length != 0 #目標ではないが乗り換えられる
        p = NowPoint.new(point.line, point.station, up[0], up[1][0], t) #出発駅→乗り換え駅のNowPoint
        if @fmap[point.line][i] == nil || @fmap[point.line][i].arriveSpeed > p.arriveSpeed #乗り換え駅の早さ最高記録なら
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1 #さらにその乗り換え先の駅について
            k = @lines[point.line].stations[i].trans[j] #乗り換え先の路線、駅、乗り換え所要時間の格納
            p2 = NowPoint.new(point.line, i, p.h2, p.m2, k[2]) #乗り換え駅→乗り換え先駅のNowPoint
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].arriveSpeed > p2.arriveSpeed #乗り換え先駅の早さ最高記録なら
              @fmap[k[0]][k[1]] = p2   #塗り替え
              p3 = NowPoint.new(k[0], k[1], p2.h2, p2.m2)
              if k[0] == goal[0] && k[1] == goal[1] && @pq.rewrite(p3) == true
                @pq.record = p3
              else
                @pq.enq(p3) #乗り換え先駅のNowPoint
              end
            end
          end
        end
      end
    end
    if up[1][2] != @lines[point.line].size-1 #その線路の途中までしか行かない場合
      useUpTrain(NowPoint.new(point.line, point.station, up[0], up[1][0]+1), goal, up[1][2]) #次の電車も調べる
      #up[1][0]+1により60分となることがあるがそれはアルゴリズム上気にする必要ない
    end
    return true
  end

  def useDownTrain(point, goal, highlim) #逆方向への電車を探す
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
        p = NowPoint.new(point.line, point.station, down[0], down[1][0], t)
        p2 = NowPoint.new(goal[0], goal[1], p.h2, p.m2)
        if @pq.rewrite(p2) == true
          @fmap[point.line][i] = p
          @pq.record = p2
        end
      elsif @lines[point.line].stations[i].trans.length != 0
        p = NowPoint.new(point.line, point.station, down[0], down[1][0], t)
        if @fmap[point.line][i] == nil || @fmap[point.line][i].arriveSpeed > p.arriveSpeed
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1
            k = @lines[point.line].stations[i].trans[j]
            p2 = NowPoint.new(point.line, i, p.h2, p.m2, k[2])
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].arriveSpeed > p2.arriveSpeed
              @fmap[k[0]][k[1]] = p2
              p3 = NowPoint.new(k[0], k[1], p2.h2, p2.m2)
              if k[0] == goal[0] && k[1] == goal[1] && @pq.rewrite(p3) == true
                @pq.record = p3
              else
                @pq.enq(p3)
              end
            end
          end
        end
      end
    end
    if down[1][2] != 0
      useDownTrain(NowPoint.new(point.line, point.station, down[0], down[1][0]+1), goal, down[1][2])
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
    if @fmap[start[0]][start[1]] != nil
      trav(sStart, sGoal, @fmap[start[0]][start[1]].h1, @fmap[start[0]][start[1]].m1)
    elsif start == goal
      print "到着です。\n"
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
              p3 = BackNowPoint.new(k[0], k[1], p2.h2, p2.m2)
              if k[0] == start[0] && k[1] == start[1] && @pq.rewrite(p3) == true
                @pq.record == p3
              else
                @pq.enq(p3)
              end
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
              p3 = BackNowPoint.new(k[0], k[1], p2.h2, p2.m2)
              if k[0] == start[0] && k[1] == start[1] && @pq.rewrite(p3) == true
                @pq.record == p3
              else
                @pq.enq(p3)
              end
            end
          end
        end
      end
    end
    if down[1][1] != @lines[point.line].size-1
      backDownTrain(NowPoint.new(point.line, point.station, down[0], down[1][0]-1), start, down[1][1])
    end
  end



  def travTransTime(start, goal, h, m) #駅から駅への最短経路。現在時刻とともに引数を渡す。メインディッシュとなる関数。
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
      useUpTrainTrans(d, goal, d.station)
      useDownTrainTrans(d, goal, d.station)
      if @pq.record != nil && @pq.record < @pq.a[0]
        @pq.heapSize = 0
      end
    end
    if @fmap[goal[0]][goal[1]] != nil  || start == goal
      traceTrans(goal, start)
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
        p = NowPointTrans.new(point.line, point.station, up[0], up[1][0], point.transTime+1, t) #出発駅→目標の駅のNowPoint
        p2 = NowPointTrans.new(goal[0], goal[1], p.h2, p.m2, point.transTime+1) #目標の駅のNowPoint
        if @pq.rewrite(p2) == true #このNowPointが早さ最高記録なら
          @fmap[point.line][i] = p
          @pq.record = p2 #塗り替え
        end
      elsif @lines[point.line].stations[i].trans.length != 0 #目標ではないが乗り換えられる
        p = NowPointTrans.new(point.line, point.station, up[0], up[1][0], point.transTime+1, t) #出発駅→乗り換え駅のNowPoint
        if @fmap[point.line][i] == nil || @fmap[point.line][i].arriveSpeed > p.arriveSpeed #乗り換え駅の早さ最高記録なら
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1 #さらにその乗り換え先の駅について
            k = @lines[point.line].stations[i].trans[j] #乗り換え先の路線、駅、乗り換え所要時間の格納
            p2 = NowPointTrans.new(point.line, i, p.h2, p.m2, point.transTime+1, k[2]) #乗り換え駅→乗り換え先駅のNowPoint
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].arriveSpeed > p2.arriveSpeed #乗り換え先駅の早さ最高記録なら
              @fmap[k[0]][k[1]] = p2   #塗り替え
              p3 = NowPointTrans.new(k[0], k[1], p2.h2, p2.m2, point.transTime+1)
              if k[0] == goal[0] && k[1] == goal[1] && @pq.rewrite(p3) == true
                @pq.record = p3
              else
                @pq.enq(p3) #乗り換え先駅のNowPoint
              end
            end
          end
        end
      end
    end
    if up[1][2] != @lines[point.line].size-1 #その線路の途中までしか行かない場合
      useUpTrainTrans(NowPointTrans.new(point.line, point.station, up[0], up[1][0]+1, point.transTime), goal, up[1][2]) #次の電車も調べる
      #up[1][0]+1により60分となることがあるがそれはアルゴリズム上気にする必要ない
    end
    return true
  end

  def useDownTrainTrans(point, goal, highlim) #逆方向への電車を探す
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
        p = NowPointTrans.new(point.line, point.station, down[0], down[1][0], point.transTime+1, t)
        p2 = NowPointTrans.new(goal[0], goal[1], p.h2, p.m2, point.transTime+1)
        if @pq.rewrite(p2) == true
          @fmap[point.line][i] = p
          @pq.record = p2
        end
      elsif @lines[point.line].stations[i].trans.length != 0
        p = NowPointTrans.new(point.line, point.station, down[0], down[1][0], point.transTime+1, t)
        if @fmap[point.line][i] == nil || @fmap[point.line][i].arriveSpeed > p.arriveSpeed
          @fmap[point.line][i] = p
          for j in 0..@lines[point.line].stations[i].trans.length-1
            k = @lines[point.line].stations[i].trans[j]
            p2 = NowPointTrans.new(point.line, i, p.h2, p.m2, point.transTime+1, k[2])
            if @fmap[k[0]][k[1]] == nil || @fmap[k[0]][k[1]].arriveSpeed > p2.arriveSpeed
              @fmap[k[0]][k[1]] = p2
              p3 = NowPointTrans.new(k[0], k[1], p2.h2, p2.m2, point.transTime+1)
              if k[0] == goal[0] && k[1] == goal[1] && @pq.rewrite == true
                @pq.record = p3
              else
                @pq.enq(p3)
              end
            end
          end
        end
      end
    end
    if down[1][2] != 0
      useDownTrainTrans(NowPointTrans.new(point.line, point.station, down[0], down[1][0]+1, point.transTime), goal, down[1][2])
    end
    return true
  end


  def traceTrans(start, goal) #引数はconvertされた後の番地の配列
    if @fmap[start[0]][start[1]] == nil
      t = 0
    else
      t = @fmap[start[0]][start[1]].transTime-1
    end
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
    comments.push(t.to_s+"回乗り換えです。\n")
    for i in 0..comments.length-1
      j = comments.length-1-i
      print comments[j]
    end
    return nil
  end

end

class NowPoint #現在地と現在時刻をセットで収納。
  attr_accessor :line, :station, :h1, :m1, :h2, :m2, :arriveSpeed
  def initialize(line, station, h, m, t=nil)
    @line = line
    @station = station
    @h1 = h
    @m1 = m  #そこから出発する時刻
    if t != nil
      @h2 = @h1+t/60
      @m2 = @m1+t%60
      if @m2 > 60
        @h2 += 1
        @m2 -= 60 #そこから次に降りる駅に到着する時刻
      end
      @arriveSpeed = @h2*60+@m2 #到着時刻の早さ
    else
      @h2 = nil
      @m2 = nil
    end
  end

  #出発時刻の早さは以下のメソッドで定義。Heapクラスの計算でも利用。
  def <(other)
    return @h1 * 60 + @m1 < other.h1 * 60 + other.m1
  end
  def >(other)
    return @h1 * 60 + @m1 > other.h1 * 60 + other.m1
  end
  def ==(other)
    if other == nil
      return false
    else
      return @h1 * 60 + @m1 == other.h1 * 60 + other.m1
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



class NowPointTrans #現在地と現在時刻をセットで収納。
  attr_accessor :line, :station, :h1, :m1, :h2, :m2, :arriveSpeed, :transTime
  def initialize(line, station, h, m, transTime, t=nil)
    @line = line
    @station = station
    @h1 = h
    @m1 = m  #そこから出発する時刻
    @transTime = transTime
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





class PriorityQueue  #NowPointやBackNowPointの優先度付き待ち行列。最小ヒープ木。
  attr_accessor :a, :heapSize, :record #recordは現時点で最も適当なNowPoint, BackNowPointを保存。
  
  def initialize(a=nil) #最初は空の配列として定義することが多いため
    if a == nil
      a=Array.new()
    end
    @a = a
    @heapSize = @a.length
    @record = nil
  end
  
  def makeHeap(i)
    l = left(i)
    r = right(i)
    smallest = i  
    if l < @heapSize and @a[l] < @a[smallest]
      smallest = l
    end
    if r < @heapSize and @a[r] < @a[smallest]
      smallest = r
    end
    if smallest != i 
      @a[i], @a[smallest] = @a[smallest], @a[i]
      makeHeap(smallest)
    end
  end
  
  def parent(i)
    return (i-1)/2
  end
  def left(i)
    return 2*i+1
  end
  def right(i)
    return 2*i+2
  end
  
  def buildHeap()
    i = @heapSize/2-1
    while i>=0
      makeHeap(i)
      i -= 1
    end
  end

  def enq(d)
    @a[@heapSize] = d
    @heapSize += 1
    heapUp(@heapSize-1)
  end
  
  def heapUp(i)
    if i > 0 then
      if @a[parent(i)] > @a[i] then
        @a[parent(i)],@a[i] = @a[i],@a[parent(i)]
        heapUp(parent(i))
      end
    end
  end
  
  def deq()
    if @heapSize > 0
      v = @a[0]
      @a[0] = @a[@heapSize -1]
      @heapSize -= 1
      makeHeap (0)
      return v
    else
      return nil
    end
  end

  def rewrite(point) #引数のpointが@recordを書き換えるのにふさわしいか調べる
    return @record == nil || point < @record
  end
end
