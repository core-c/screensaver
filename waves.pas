unit waves;
interface
uses SysUtils;

const MaxTenticleWidth=90;
type PRec = record
       x,y,
       R,G,B: single;
     end;
     TWaveArray = array[0..720+MaxTenticleWidth] of PRec;

     TStar=record
       StarPosX,StarPosY,  StarPosX_,StarPosY_,
       StarCR,StarCG,StarCB,
       StarSize: single;
     end;


     TWaves = object
     {Horizontal length of each part to draw;
      OpenGL-X in [-1..1], so valid HorPxStep in [0..2]}
       HorPxStep: single;
     {an array containing all the points of the actual wave}
       Pnt: TWaveArray;
     {the X-morphing thingies}
       Xamp,XampDiff: single;
       XSign,XShift: integer;
     {the Y-morphing thingies}
       Yamp,YampDiff: single;
       YSign: integer;
     {colorcycling thingies}
       ColR,ColG,ColB: single;
       CDiffR,CDiffG,CDiffB: single;
       ColTicksToGo: integer;
       Intensity: single;
       RightXIntensity,RightXDiff: single;
       RightXTicksToGo: integer;
       BurstR,BurstG,BurstB: single;
       BurstDiffR,BurstDiffG,BurstDiffB: single;
       BurstSize, BurstSizeDec,
       BurstDiff,
       BurstPos,
       BurstTicks: integer;
     {background color}
       BG_R,BG_G,BG_B: single;
       BGDiffR,BGDiffG,BGDiffB: single;
       BGColTicksToGo: integer;
       BG_ClearAlpha: single;
     {Stars}
       Starz: array[0..100] of TStar;
     {}
       thetaX,thetaY,thetaZ: single;
     {RandomShow}
       RandomShowTime: TDateTime;
       RandomHarmonica: boolean;
       RandomWaveGap, RandomSpan: integer;
       RandomWaveGapF, RandomWaveSpanF: single;
       RandomShift: integer;
       RandomShiftF: single;
       RandomYSwap, RandomYSwapF: single;
       RandomWavePart: integer;
       RandomWavePartF: single;
       RandomMorphRange, RandomMorphRangeF: single;
       Random3DRot: boolean;
       Random3DRotX,Random3DRotY,Random3DRotZ: integer;
       Random3DRotXF,Random3DRotYF,Random3DRotZF: single;
     private
       Width, Height: integer;
       MySinA,{}MyCosA: Array[0..359] of single;
       function SinArray(inDeg: integer): single;
       function CosArray(inDeg: integer): single;
       {OpenGL-using routines}
       procedure DrawStar(tstar: integer);
       procedure DoPart(ii,ofs: integer);
       procedure FeedPnt(idx,code: integer);
       procedure NextWave;
       procedure RandomShow;
       {}
       procedure AutoInit;
     public
       procedure Init(VWidth,VHeight: integer);
       procedure PickNewCycleColor(cR,cG,cB: single);
       procedure GLAnimate;
     end;

var Wave: TWaves;

implementation
uses check, INISettings, windows, forms,
     math, OpenGL, GLAnimate;

procedure TWaves.NextWave;
var ii,ii2,tBS,tstar: integer;
    tR,tR2,tR3,tR4: single;
    colorIntensity: single;
begin
//  randomize;

  // Random background clearing alpha
  if CFG.ClearBackground and (BG_ClearAlpha < 1.0) then begin
    BG_ClearAlpha := BG_ClearAlpha + 0.0025;
    if BG_ClearAlpha>1.0 then BG_ClearAlpha := 1.0;
  end;
  if not CFG.ClearBackground and (BG_ClearAlpha > 0.1) then begin
    BG_ClearAlpha := BG_ClearAlpha - 0.0025;
    if BG_ClearAlpha<0.1 then BG_ClearAlpha := 0.1;
  end;

  // Random span
  if CFG.Span < RandomSpan then begin
    RandomWaveSpanF := RandomWaveSpanF + 0.5;
    CFG.Span := Round(RandomWaveSpanF);
    if CFG.Span > 90 then begin
      CFG.Span := 90;
      RandomSpan := CFG.Span;
    end;
  end else
    if CFG.Span > RandomSpan then begin
      RandomWaveSpanF := RandomWaveSpanF - 0.5;
      CFG.Span := Round(RandomWaveSpanF);
      if CFG.Span < 1 then begin
        CFG.Span := 1;
        RandomSpan := CFG.Span;
      end;
    end;
  // Random gap
  if CFG.WaveGap < RandomWaveGap then begin
    RandomWaveGapF := RandomWaveGapF + 0.5;
    CFG.WaveGap := Round(RandomWaveGapF);
    if CFG.WaveGap > 90 then begin
      CFG.WaveGap := 90;
      RandomWaveGap := CFG.WaveGap;
    end;
  end else
    if CFG.WaveGap > RandomWaveGap then begin
      RandomWaveGapF := RandomWaveGapF - 0.5;
      CFG.WaveGap := Round(RandomWaveGapF);
//      if CFG.WaveGap < 2 then begin
//        CFG.WaveGap := 2;
      if CFG.WaveGap < 1 then begin
        CFG.WaveGap := 1;
        RandomWaveGap := CFG.WaveGap;
      end;
    end;
  //
  if RandomHarmonica then
    CFG.Harmonica := RandomHarmonica
  else
    if (CFG.Span = RandomSpan) and (CFG.WaveGap = RandomWaveGap) then CFG.Harmonica := RandomHarmonica;

  // Random phaseshift
  if CFG.PhaseShift < RandomShift then begin
    RandomShiftF := RandomShiftF + 0.02;
    CFG.PhaseShift := Round(RandomShiftF);
    if RandomShiftF > RandomShift then begin
      RandomShiftF := RandomShift;
      CFG.PhaseShift := RandomShift;
    end;
  end else
    if CFG.PhaseShift > RandomShift then begin
      RandomShiftF := RandomShiftF - 0.02;
      CFG.PhaseShift := Round(RandomShiftF);
      if RandomShiftF < RandomShift then begin
        RandomShiftF := RandomShift;
        CFG.PhaseShift := RandomShift;
      end;
    end;

  // Random YSwap
  if CFG.YSwap < RandomYSwap then begin
    RandomYSwapF := RandomYSwapF + 0.0005;
    CFG.YSwap := RandomYSwapF;
    if RandomYSwapF > RandomYSwap then begin
      RandomYSwapF := RandomYSwap;
      CFG.YSwap := RandomYSwap;
    end;
  end else
    if CFG.YSwap > RandomYSwap then begin
      RandomYSwapF := RandomYSwapF - 0.0005;
      CFG.YSwap := RandomYSwapF;
      if RandomYSwapF < RandomYSwap then begin
        RandomYSwapF := RandomYSwap;
        CFG.YSwap := RandomYSwap;
      end;
    end;

  // Random wavepart
  if CFG.WavePart < RandomWavePart then begin
    RandomWavePartF := RandomWavePartF + 0.05;
    CFG.WavePart := Round(RandomWavePartF);
    if RandomWavePartF > RandomWavePart then begin
      RandomWavePartF := RandomWavePart;
      CFG.WavePart := RandomWavePart;
    end;
  end else
    if CFG.WavePart > RandomWavePart then begin
      RandomWavePartF := RandomWavePartF - 0.05;
      CFG.WavePart := Round(RandomWavePartF);
      if RandomWavePartF < RandomWavePart then begin
        RandomWavePartF := RandomWavePart;
        CFG.WavePart := RandomWavePart;
      end;
    end;
  HorPxStep := 2.0/CFG.WavePart;

  // Random MorphRange
  if CFG.XMorph < RandomMorphRange then begin
    RandomMorphRangeF := RandomMorphRangeF + 0.005;
    CFG.XMorph := RandomMorphRangeF;
    if RandomMorphRangeF > RandomMorphRange then begin
      RandomMorphRangeF := RandomMorphRange;
      CFG.XMorph := RandomMorphRange;
    end;
  end else
    if CFG.XMorph > RandomMorphRange then begin
      RandomMorphRangeF := RandomMorphRangeF - 0.005;
      CFG.XMorph := RandomMorphRangeF;
      if RandomMorphRangeF < RandomMorphRange then begin
        RandomMorphRangeF := RandomMorphRange;
        CFG.XMorph := RandomMorphRange;
      end;
    end;

  // Random 3D Rotation
  // X
  if CFG._3DRotX < Random3DRotX then begin
    Random3DRotXF := Random3DRotXF + 0.1;
    CFG._3DRotX := Round(Random3DRotXF);
    if Random3DRotXF > Random3DRotX then begin
      Random3DRotXF := Random3DRotX;
      CFG._3DRotX := Random3DRotX;
      CFG._3DRot := true;
    end;
  end else
    if CFG._3DRotX > Random3DRotX then begin
      Random3DRotXF := Random3DRotXF - 0.1;
      CFG._3DRotX := Round(Random3DRotXF);
      if Random3DRotXF < Random3DRotX then begin
        Random3DRotXF := Random3DRotX;
        CFG._3DRotX := Random3DRotX;
        CFG._3DRot := false;
      end;
    end;
  // Y
  if CFG._3DRotY < Random3DRotY then begin
    Random3DRotYF := Random3DRotYF + 0.1;
    CFG._3DRotY := Round(Random3DRotYF);
    if Random3DRotYF > Random3DRotY then begin
      Random3DRotYF := Random3DRotY;
      CFG._3DRotY := Random3DRotY;
      CFG._3DRot := true;
    end;
  end else
    if CFG._3DRotY > Random3DRotY then begin
      Random3DRotYF := Random3DRotYF - 0.1;
      CFG._3DRotY := Round(Random3DRotYF);
      if Random3DRotYF < Random3DRotY then begin
        Random3DRotYF := Random3DRotY;
        CFG._3DRotY := Random3DRotY;
        CFG._3DRot := false;
      end;
    end;
  // Z
  if CFG._3DRotZ < Random3DRotZ then begin
    Random3DRotZF := Random3DRotZF + 0.1;
    CFG._3DRotZ := Round(Random3DRotZF);
    if Random3DRotZF > Random3DRotZ then begin
      Random3DRotZF := Random3DRotZ;
      CFG._3DRotZ := Random3DRotZ;
      CFG._3DRot := true;
    end;
  end else
    if CFG._3DRotZ > Random3DRotZ then begin
      Random3DRotZF := Random3DRotZF - 0.1;
      CFG._3DRotZ := Round(Random3DRotZF);
      if Random3DRotZF < Random3DRotZ then begin
        Random3DRotZF := Random3DRotZ;
        CFG._3DRotZ := Random3DRotZ;
        CFG._3DRot := false;
      end;
    end;

  // Random intensity
  colorIntensity := (ColR+ColG+ColB) * BG_ClearAlpha /2; ///3;
  if Intensity > colorIntensity then Intensity := Intensity - 0.005;
  if Intensity < colorIntensity then Intensity := Intensity + 0.005;


  if CFG.Harmonica then begin
    ii:=CFG.Span;
    while not (ii mod CFG.WaveGap=0) do inc(ii);
    repeat
      tR:=SinArray(ii);
      tR2:=SinArray(ii+Xshift);
      tR3:=Intensity*tR;
      Pnt[ii].x:=((ii*HorPxStep)-1.0)  +  Xamp*CosArray(ii+Xshift)*tR2;
      Pnt[ii].y:=Yamp*tR2 + Xamp*CosArray(ii)*tR;
      Pnt[ii].R:=abs(ColR*tR3);
      Pnt[ii].G:=abs(ColG*tR3);
      Pnt[ii].B:=abs(ColB*tR3);
      if CFG.ColorBurst then
        if (ii>BurstPos-BurstSize) and (ii<BurstPos+BurstSize) then begin
          tR4:={TB_BurstIntensity.max+1}16-CFG.BurstIntensity;
          Pnt[ii].R:=Pnt[ii].R + (BurstSize-abs(ii-BurstPos))/tR4*BurstR;
          Pnt[ii].G:=Pnt[ii].G + (BurstSize-abs(ii-BurstPos))/tR4*BurstG;
          Pnt[ii].B:=Pnt[ii].B + (BurstSize-abs(ii-BurstPos))/tR4*BurstB;
        end;
(*
      if CFG.RightX then begin
        tR4:=(ii/CFG.WavePart)*RightXIntensity;
        Pnt[ii].R:=Pnt[ii].R * tR4;
        Pnt[ii].G:=Pnt[ii].G * tR4;
        Pnt[ii].B:=Pnt[ii].B * tR4;
      end;
*)
      {}
      ii2:=ii-CFG.Span;
      tR:=SinArray(ii2);
      tR2:=SinArray(ii2+Xshift);
      tR3:=Intensity*tR;
      Pnt[ii2].x:=((ii2*HorPxStep)-1.0)  +  Xamp*CosArray(ii2+Xshift)*tR2;
      Pnt[ii2].y:=Yamp*tR2 + Xamp*CosArray(ii2)*tR;
      Pnt[ii2].R:=abs(ColR*tR3);
      Pnt[ii2].G:=abs(ColG*tR3);
      Pnt[ii2].B:=abs(ColB*tR3);
      if CFG.ColorBurst then
        if (ii2>BurstPos-BurstSize) and (ii2<BurstPos+BurstSize) then begin
          tR4:={TB_BurstIntensity.max+1}16-CFG.BurstIntensity;
          Pnt[ii2].R:=Pnt[ii2].R + (BurstSize-abs(ii2-BurstPos))/tR4*BurstR;
          Pnt[ii2].G:=Pnt[ii2].G + (BurstSize-abs(ii2-BurstPos))/tR4*BurstG;
          Pnt[ii2].B:=Pnt[ii2].B + (BurstSize-abs(ii2-BurstPos))/tR4*BurstB;
        end;
(*
      if CFG.RightX then begin
        tR4:=(ii2/CFG.WavePart)*RightXIntensity;
        Pnt[ii2].R:=Pnt[ii2].R * tR4;
        Pnt[ii2].G:=Pnt[ii2].G * tR4;
        Pnt[ii2].B:=Pnt[ii2].B * tR4;
      end;
*)
      {}
      ii:=ii+CFG.WaveGap;
    until (ii>CFG.WavePart);
  end else
    {not CFG.Harmonica}
    for ii:=0 to CFG.WavePart-1 do begin
      tR:=SinArray(ii);
      tR2:=SinArray(ii+Xshift);
      Pnt[ii].x:=((ii*HorPxStep)-1.0)  +  Xamp*CosArray(ii+Xshift)*tR2;
      Pnt[ii].y:=Yamp*tR2 + Xamp*CosArray(ii)*tR;
      Pnt[ii].R:=abs(ColR*Intensity*tR);
      Pnt[ii].G:=abs(ColG*Intensity*tR);
      Pnt[ii].B:=abs(ColB*Intensity*tR);
      if CFG.ColorBurst then
        if (ii>BurstPos-BurstSize) and (ii<BurstPos+BurstSize) then begin
          tR4:={TB_BurstIntensity.max+1}16-CFG.BurstIntensity;
          Pnt[ii].R:=Pnt[ii].R + (BurstSize-abs(ii-BurstPos))/tR4*BurstR;
          Pnt[ii].G:=Pnt[ii].G + (BurstSize-abs(ii-BurstPos))/tR4*BurstG;
          Pnt[ii].B:=Pnt[ii].B + (BurstSize-abs(ii-BurstPos))/tR4*BurstB;
        end;
    end;

  {apply horizontal 'morphing'}
  XampDiff:=XSign*CFG.MorphSpeed;
  Xamp:=Xamp+XampDiff;
  if (Xamp>CFG.XMorph) or (Xamp<-CFG.XMorph) then XSign:=-XSign;

  {Phase swapping}
  YampDiff:=YSign*CFG.YSwap;
  Yamp:=Yamp+YampDiff;
  if (Yamp>1.0) or (Yamp<-1.0) then YSign:=-YSign;

  {Phase shifting}
  Xshift:=(Xshift+360-CFG.PhaseShift) mod 360;

  {colorcycling}
  if CFG.ColorCycle then
    if ColTicksToGo>0 then begin
      Dec(ColTicksToGo);
      ColR:=ColR+CDiffR; ColG:=ColG+CDiffG; ColB:=ColB+CDiffB;
    end else
      PickNewCycleColor(ColR,ColG,ColB);


(*
  {Right side of wave colorcycling}
  CFG.RightX:=true;
  if CFG.RightX then
    if RightXTicksToGo>0 then begin
      Dec(RightXTicksToGo);
      RightXIntensity:=RightXIntensity+RightXDiff;
    end else begin
      RightXTicksToGo:=10+random(12);
      RightXDiff:=(random*20-RightXIntensity)/RightXTicksToGo;
    end;
*)


  {colorburst}
  if CFG.ColorBurst then
    if BurstTicks>0 then begin
      Dec(BurstTicks);
      BurstPos:=BurstPos+BurstDiff;
      BurstR:=BurstR+BurstDiffR;
      BurstG:=BurstG+BurstDiffG;
      BurstB:=BurstB+BurstDiffB;
      if BurstSizeDec<0 then begin
        Inc(BurstSizeDec);
        Inc(BurstSize);
      end;
      if BurstSizeDec>0 then begin
        Dec(BurstSizeDec);
        Dec(BurstSize);
      end;
    end else begin
      BurstTicks:=10+random(60);
      BurstDiff:=(random(CFG.Wavepart)-BurstPos) div BurstTicks;
      {burstSize wordt kleiner naarmate BurstDiff vergroot}
      tBS:=BurstSize;
      BurstSize:=30-round( (CFG.Wavepart div 30)/abs(BurstDiff) );
      BurstSizeDec:=BurstSize-tBS;
      BurstDiffR:=(random-BurstR)/BurstTicks;
      BurstDiffG:=(random-BurstG)/BurstTicks;
      BurstDiffB:=(random-BurstB)/BurstTicks;
    end;

    {Stars}
    if CFG.Stars then begin
      tR4:=0.1;
      for tstar:=1 to CFG.NrOfStars do with starz[tstar] do Begin
        StarPosX:=StarPosX*1.0202;
        StarPosY:=StarPosY*1.02;
        StarSize:=StarSize/1.1;
        if StarCR-tR4>=0 then StarCR:=StarCR-tR4 else StarCR:=0;
        if StarCG-tR4>=0 then StarCG:=StarCG-tR4 else StarCG:=0;
        if StarCB-tR4>=0 then StarCB:=StarCB-tR4 else StarCB:=0;
        if (StarCR+StarCG+StarCB)=0 then begin
          repeat
            StarPosX:=StarPosX_+((random/4)-(1/8));
          until ( (StarPosX>-1.0) and (StarPosX<1.0) );
          StarPosX_:=StarPosX;
          repeat
            StarPosY:=StarPosY_+((random/4)-(1/8));
          until ( (StarPosY>-1.0) and (StarPosY<1.0) );
          StarPosY_:=StarPosY;

          if CFG.MultiColorStars then begin
            StarCR:=random; StarCG:=random; StarCB:=random;
          end else begin
            StarCR:=random; StarCG:=StarCR; StarCB:=StarCR;
          end;
          StarSize:=random/64;
        end;

      end;
    end;

(*
  if CFG.BGCycle then
    if BGColTicksToGo>0 then begin
      Dec(BGColTicksToGo);
      BG_R:=BG_R+BGDiffR; BG_G:=BG_G+BGDiffG; BG_B:=BG_B+BGDiffB;
    end else begin
      BGColTicksToGo:=1*30+Random(20);
      BGDiffR:=(random-BG_R)/(BGColTicksToGo-1);
      BGDiffG:=(random-BG_G)/(BGColTicksToGo-1);
      BGDiffB:=(random-BG_B)/(BGColTicksToGo-1);
    end;
*)

end;


procedure TWaves.RandomShow;
var tmpInt: integer;
    tmpFloat: single;
    RandomIndex: integer;
    CurTime: TDateTime;
    loops: integer;
begin
  // a show runs for minimum 10 seconds, and maximum 30 seconds
  if not CFG.RandomShow then Exit;
  Randomize;
  CurTime := Time;
  if RandomShowTime - CurTime > 0 then Exit;
  RandomShowTime := CurTime + ((Random(20)+10) * 1.1574074074074074074074074074074e-5);

  CFG.ColIntensity := 1;
  CFG.ClearBackground := not CFG.ClearBackground;
  CFG.ColorBurst := false;
  CFG.ColorCycle := true;
  CFG.Stars := false;
  CFG._3DRot := true;
  CFG.RightX := true;
  if Random(75) < 35 then RandomHarmonica := not RandomHarmonica;
  RandomWavePart := 540;
  RandomWavePartF := CFG.WavePart;
  HorPxStep := 2.0/CFG.WavePart;

  for loops:=0 to 6 do begin
    RandomIndex := Random(16+1);
    case RandomIndex of
      0: begin
           {Force saver to clear the background each frame}
           CFG.ClearBackground := not CFG.ClearBackground;
         end;

      1: begin
           {xtra intensity of the core wave}
           tmpInt := Random(101);
           CFG.CoreWave := 1.0+(tmpInt*0.01);
         end;

      2: begin
           {length of wave (e.g. 90..720 degrees)}
           tmpInt := Random(4);
           case tmpInt of
             0: RandomWavePart := 180;
             1: RandomWavePart := 360;
             2: RandomWavePart := 540;
             3: RandomWavePart := 720;
           end;
           RandomWavePartF := CFG.WavePart;
           HorPxStep:=2.0/CFG.WavePart;
         end;

      3: begin
           tmpInt := Random(50);
           if tmpInt < 35 then begin
             {morph amount in horizontal direction}
             tmpInt := Random(150)+1;
             RandomMorphRange := 0.025 * tmpInt;
             RandomMorphRangeF := CFG.XMorph;
           end else begin
             //tmpInt := Random(21);
             tmpInt := Random(5);
             CFG.MorphSpeed := 0.00001 * tmpInt;
           end;
         end;

      4: begin
           {phase swapping speed}
           //tmpInt := Random(11);
           //CFG.YSwap := 0.005*(10-tmpInt);
           tmpInt := Random(5);
           RandomYSwap := 0.005*(4-tmpInt);
           RandomYSwapF := CFG.YSwap;
         end;

      5: begin
           {in degrees}
           //tmpInt := Random(21)-10;
           tmpInt := Random(7)-3;
           RandomShift := tmpInt;
           RandomShiftF := CFG.PhaseShift;
         end;

      6: begin
           {CoreWave thickness in pixels}
           tmpInt := Random(50)+1;
           CFG.LineWidth := tmpInt;
         end;

      7: begin
           {Colorcycling not yet finished!!!}
           tmpInt := Random(50);
           if tmpInt < 25 then
             CFG.ColorCycle := not CFG.ColorCycle
           else
             CFG.Xtra := not CFG.Xtra;
         end;

      8: begin
           {if true: right screen-side will be different intensity}
           CFG.RightX := not CFG.RightX;
         end;

      9: begin
           {weer iets experimenteels! haha}
           tmpInt := Random(50);
           if tmpInt < 25 then
             CFG.ColorBurst := not CFG.ColorBurst
           else begin
             tmpInt := Random(15)+1;
             CFG.BurstIntensity := tmpInt;
           end;
         end;

      10: begin
            {max color-intensity scaling factor}
            if RandomHarmonica or (not CFG.ClearBackground) then begin
              tmpInt := Random(10)+1;
              CFG.ColIntensity := tmpInt;
            end else begin
              tmpInt := Random(3)+1;
              CFG.ColIntensity := tmpInt;
            end;  
          end;

      11: begin
            {cycle background-color}
            CFG.BGCycle := not CFG.BGCycle;
          end;

      12: begin
            tmpInt := Random(75);
            if tmpInt < 25 then begin
              {the waves are drawn like a harmonica}
              RandomHarmonica := not RandomHarmonica;
            end;
            if RandomHarmonica then begin
              {harmonica gaps}
              tmpInt := Random(89)+2;
              RandomWaveGap := tmpInt;
              RandomWaveGapF := CFG.WaveGap;
              {width of harmonica-tentacles}
              tmpInt := Random(90)+1;
              RandomSpan := tmpInt;
              RandomWaveSpanF := CFG.Span;
            end;
          end;

      13: begin
            {true=2 punten (0,1)&(0,-1),  false=1 (0,0)}
            CFG.FadePoints := not CFG.FadePoints;
          end;

      14: begin
            tmpInt := Random(75);
            if tmpInt < 15 then
              {twinkling stars on/off}
              CFG.Stars := not CFG.Stars
            else if tmpInt < 50 then begin
              {max. is TB_NrOfStars.max}
              tmpInt := Random(100)+1;
              CFG.NrOfStars := tmpInt;
            end else
              CFG.MultiColorStars := not CFG.MultiColorStars;
          end;

      15: begin
            tmpInt := Random(100);
            if tmpInt < 15 then begin
              {if true: 3D-rotation is enabled, else everything is 2D only }
              Random3DRot := not Random3DRot;
              if not Random3DRot then begin
                Random3DRotX := 0;
                Random3DRotY := 0;
                Random3DRotZ := 0;
                Random3DRotXF := CFG._3DRotX;
                Random3DRotYF := CFG._3DRotY;
                Random3DRotZF := CFG._3DRotZ;
              end;
            end else if tmpInt < 50 then begin
              {RotX,-Y and -Z / 10.0 = actual degrees}
              tmpInt := Random(11);
              Random3DRotX := tmpInt;
              Random3DRotXF := CFG._3DRotX;
            end else if tmpInt < 75 then begin
              tmpInt := Random(11);
              Random3DRotY := tmpInt;
              Random3DRotYF := CFG._3DRotY;
            end else begin
              tmpInt := Random(11);
              Random3DRotZ := tmpInt;
              Random3DRotZF := CFG._3DRotZ;
            end;
          end;
    end;
  end;

  if RandomHarmonica then begin
    tmpInt := Random(50);
    if tmpInt < 25 then begin
      {harmonica gaps}
      tmpInt := Random(89)+2;
      RandomWaveGap := tmpInt;
    end else begin
      {width of harmonica-tentacles}
      tmpInt := Random(90)+1;
      RandomSpan := tmpInt;
    end;
  end else begin
//    RandomWaveGap := 2;
    RandomWaveGap := 1;
    RandomSpan := 1;
  end;
  RandomWaveGapF := CFG.WaveGap;
  RandomWaveSpanF := CFG.Span;
end;


procedure TWaves.PickNewCycleColor(cR,cG,cB: single);
var tR,tG,tB: single;
    tSec,RR: integer;
begin
  Randomize;
  if CFG.Xtra then begin
    tSec:=Round(FramesDropped/30*3*30);
    tR:=random;  tG:=random;  tB:=random;
  end else begin
    tSec:=13*30;
    tR:=cR;  tG:=cG;  tB:=cB;
    RR:=random(1234) mod 3;
    case RR of
      0: tR:=random;
      1: tG:=random;
      2: tB:=random;
    end;
  end;
  ColTicksToGo:=15*20+Random(tSec);  {min-max fadetime = 2..15 sec.}
  CDiffR:=(tR-cR)/ColTicksToGo;
  CDiffG:=(tG-cG)/ColTicksToGo;
  CDiffB:=(tB-cB)/ColTicksToGo;
end;




{=========================================================}
{===   OpenGL routines                                 ===}
{=========================================================}


procedure TWaves.DrawStar(tstar: integer);
var t1,t2,t3: single;
begin
  with starz[tstar] do begin
    glBegin(GL_TRIANGLES);
      t1:=StarPosX; t2:=StarPosY; t3:=StarSize;
      glColor3f( StarCR,StarCG,StarCB );  glVertex2f( t1,t2 );
      glColor3f( 0, 0, 0 );  glVertex2f( t1-t3,t2 ); glVertex2f( t1,t2-t3 );
      glColor3f( StarCR,StarCG,StarCB );  glVertex2f( t1,t2 );
      glColor3f( 0, 0, 0 );  glVertex2f( t1,t2-t3 ); glVertex2f( t1+t3,t2 );
      glColor3f( StarCR,StarCG,StarCB );  glVertex2f( t1,t2 );
      glColor3f( 0, 0, 0 );  glVertex2f( t1+t3,t2 ); glVertex2f( t1,t2+t3 );
      glColor3f( StarCR,StarCG,StarCB );  glVertex2f( t1,t2 );
      glColor3f( 0, 0, 0 );  glVertex2f( t1,t2+t3 ); glVertex2f( t1-t3,t2 );
    glEnd();
  end;
end;


procedure TWaves.FeedPnt(idx,code: integer);
const _3Dz=0.45000;
      _3Dy=0.70000;
begin
  With Wave.Pnt[idx] do
    case code of
      0: begin
        glColor3f( R, G, B );                {zomaar n getalletje die _3Dy}
        if CFG._3DRot then glVertex3f( x, y, _3Dy*sinArray(idx) )
                      else glVertex2f( x, y );
      end;
      1: begin
        glColor3f( R*CFG.CoreWave, G*CFG.CoreWave, B*CFG.CoreWave );
        if CFG._3DRot then glVertex3f( x, y, _3Dy*sinArray(idx) )
                      else glVertex2f( x, y );
      end;
      2: begin
        glColor3f( Wave.BG_R, Wave.BG_G, Wave.BG_B );
        if CFG._3DRot then glVertex3f( 0.0,_3Dy,-_3Dz )
                      else glVertex2f( 0.0,_3Dy );
      end;
      3: begin
        glColor3f( Wave.BG_R, Wave.BG_G, Wave.BG_B );
        if CFG._3DRot then glVertex3f( 0.0,-(_3Dy),-_3Dz )
                      else glVertex2f( 0.0,-(_3Dy) );
      end;
      4: begin
        glColor3f( Wave.BG_R, Wave.BG_G, Wave.BG_B );
        if CFG._3DRot then glVertex3f( 0.0,0.0,-_3Dz )
                      else glVertex2f( 0.0,0.0 );
      end
    end
end;


procedure TWaves.DoPart(ii,ofs: integer);
begin
  {check of 2 fade-punten te tekenen}
  if CFG.FadePoints then begin
    glBegin(GL_TRIANGLE_STRIP);
     FeedPnt(0,2);
     FeedPnt(ii-ofs,0);
     FeedPnt(ii,0);
     FeedPnt(0,3);
    glEnd();
  end else begin
    glBegin(GL_TRIANGLES);
     FeedPnt(0,4);
     FeedPnt(ii-ofs,0);
     FeedPnt(ii,0);
    glEnd();
  end;

  {the CoreLine}
//  if CFG.CoreWave>1.0 then begin
    glBegin(GL_LINES);
     FeedPnt(ii-ofs,1);
     FeedPnt(ii,1);
    glEnd();
//  end;
end;


procedure TWaves.GLAnimate;
var ii,WPd2,tstar: integer;
    TextureHandle: cardinal;
    viewport: array[0..3] of GLint;
begin
  CoreGL.StillBusy:=true;
(*
  if CFG.ClearBackground and (BG_ClearAlpha=1.0) then begin
    glDisable(GL_BLEND);
    glClearColor(BG_R, BG_G, BG_B, 0.0);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  end else begin
*)

//  glPixelStorei(GL_PACK_ALIGNMENT, 1);
//  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

  glGetIntegerv(GL_VIEWPORT, @viewport);
// @ glViewPort(0,0,Width,Height);

//    glClear(GL_DEPTH_BUFFER_BIT);

  // anti flickering
  glMatrixMode(GL_PROJECTION);
  glPushMatrix();
  glLoadIdentity();
  gluOrtho2D(0,Width, 0,Height);
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix();
  glLoadIdentity();
  glDisable(GL_BLEND);
  glReadBuffer(GL_FRONT);
  glDrawBuffer(GL_BACK);
  glRasterPos2i(0,0);
  // copy to screen
  glCopyPixels(0,0,Width*viewport[2],Height*viewport[3], GL_COLOR);
(*
    // copy to texture
    if Assigned(glCopyTexImage2D) then begin
      glGenTextures(1, TextureHandle);
      glBindTexture(GL_TEXTURE_2D, TextureHandle);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 512,512, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
      glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, viewport[0],viewport[1],512,512, 0);
    end;
*)
  glMatrixMode(GL_PROJECTION);
  glPopMatrix();
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix();

  // restore the viewport
//@  glViewPort(viewport[0],viewport[1],viewport[2],viewport[3]);

  // fade to black by overlapping the screen with an alpha-black quad
//glDisable(GL_DEPTH_TEST);
//glDrawBuffer(GL_FRONT_AND_BACK);
  glEnable(GL_BLEND);
//glBlendFunc(GL_ONE, GL_DST_ALPHA);
//glBlendFunc(GL_SRC_ALPHA_SATURATE, GL_SRC_ALPHA);
//glBlendFunc(GL_SRC_ALPHA_SATURATE, GL_ONE_MINUS_SRC_ALPHA);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  // beetje faden naar zwart..
  glColor4f(0,0,0, BG_ClearAlpha);
  glBegin(GL_QUADS);
    glVertex2f(-1,-1);
    glVertex2f(1,-1);
    glVertex2f(1,1.11); //!!!!
    glVertex2f(-1,1.11); //!!!!
  glEnd;
//glDrawBuffer(GL_BACK);
  glBlendFunc(GL_ONE, GL_ONE);
(*
  end;
*)

(*
    // screen to texture gedoe..
    if Assigned(glCopyTexImage2D) then begin
      glFrontFace(GL_CCW);
      glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
      glEnable(GL_TEXTURE_2D);
      glBindTexture(GL_TEXTURE_2D, TextureHandle);
      glBegin(GL_QUADS);
        glColor4f(0.4,0.4,0.4,BG_ClearAlpha);
        for ii:=20 downto 1 do begin
          glTexCoord2D(0,0);
          glVertex2f(-(ii/20), -(ii/20));
          glTexCoord2D(1,0);
          glVertex2f((ii/20), -(ii/20));
          glTexCoord2D(1,1);
          glVertex2f((ii/20), (ii/20));
          glTexCoord2D(0,1);
          glVertex2f(-(ii/20), (ii/20));
        end;
      glEnd;
      glDisable(GL_TEXTURE_2D);
      glDeleteTextures(1, @TextureHandle);
      glBlendFunc(GL_ONE, GL_ONE);
    end;
*)


  if CFG.Stars then
    for tstar:=1 to CFG.NrOfStars do DrawStar(tstar);

  if CFG._3DRot then begin
    glPushMatrix();
    glRotatef( thetaX,   1.0, 0.0, 0.0);
    glRotatef( thetaY,   0.0, 1.0, 0.0);
    glRotatef( thetaZ,   0.0, 0.0, 1.0);
  end;

  glLineWidth(CFG.LineWidth);

  if (not CFG.Harmonica) then begin
    {draw left 2 right}
    for ii:=1 to (CFG.WavePart div 2) do DoPart(ii,1);
    {draw right 2 left}
    for ii:=(CFG.WavePart-1) downto (CFG.WavePart div 2) do DoPart(ii,1);
    {}
  end else begin

    {draw left 2 right -------}
    WPd2:=CFG.WavePart div 2;
    ii:=CFG.Span;
    while not (ii mod CFG.WaveGap=0) do inc(ii);
    repeat
      DoPart(ii,CFG.Span);
      ii:=ii+CFG.WaveGap;
    until (ii>WPd2);
    {draw right 2 left ---------}
    ii:=CFG.WavePart-1;
    while not (ii mod CFG.WaveGap=0) do dec(ii);
    repeat
      DoPart(ii,CFG.Span);
      ii:=ii-CFG.WaveGap;
    until (ii<WPd2);

  end;

  if CFG._3DRot then begin
    glPopMatrix();
    thetaX:=thetaX+(CFG._3DRotX/10);  if thetaX>=360.0 then thetaX:=0.0;
    thetaY:=thetaY+(CFG._3DRotY/10);  if thetaY>=360.0 then thetaY:=0.0;
    thetaZ:=thetaZ+(CFG._3DRotZ/10);  if thetaZ>=360.0 then thetaZ:=0.0;
  end;

  SwapBuffers(handleDC);

  application.processmessages;
  Wave.NextWave;
  Wave.RandomShow;
  CoreGL.StillBusy:=false;
end;


{=========================================================}






procedure TWaves.Init(VWidth,VHeight: integer);
var ii: integer;
begin
  Width:=VWidth;  Height:=VHeight;
  thetaX:=0;  thetaY:=0;  thetaZ:=0;
  Xamp:=0.0;  XSign:=1;  XampDiff:=0.0;  XShift:=0;
  Yamp:=1.0;  YSign:=1;  YampDiff:=0.0;
  Intensity:=CFG.ColIntensity/10.0;
  ColTicksToGo:=150;  ColR:=0.0;  ColG:=0.0;  ColB:=1.0;
  RightXIntensity:=0.0;  RightXDiff:=0.0;  RightXTicksToGo:=300;
  BurstR:=1.0; BurstG:=1.0; BurstB:=1.0;
  BurstDiffR:=0; BurstDiffG:=0; BurstDiffB:=0;
  BurstTicks:=10;  BurstPos:=0;  BurstDiff:=0;
  BurstSize:=10;  BurstSizeDec:=0;
  BGColTicksToGo:=500;  BG_R:=0.0;  BG_G:=0.0;  BG_B:=0.0;
  BGDiffR:=0.0;  BGDiffG:=0.0;  BGDiffB:=0.0;
  BG_ClearAlpha:=0.1;
  HorPxStep:=2.0/CFG.WavePart;{OpenGL-X in [-1.0..1.0] => 2.0 wide}
  for ii:=0 to CFG.WavePart+MaxTenticleWidth do begin
    Pnt[ii].x:=((ii*HorPxStep)-1.0)  +  Xamp*CosArray(ii+Xshift)*SinArray(ii+Xshift);
    Pnt[ii].y:=Yamp*SinArray(ii+Xshift) + Xamp*CosArray(ii)*SinArray(ii);
    Pnt[ii].R:=ColR;  Pnt[ii].G:=ColG;  Pnt[ii].B:=ColB*Intensity*SinArray(ii)
  end;
  if CFG.RandomShow then begin
    RandomShowTime := 0;
    Random3DRotX := Random(3);
    Random3DRotY := Random(3);
    Random3DRotZ := Random(3);
    RandomMorphRange := 1.875;
    RandomMorphRangeF := 1.875;
    CFG.XMorph := 1.875;
    CFG.MorphSpeed := 0.00001;
    RandomShift := 1;
    RandomShiftF := 1;
    CFG.PhaseShift := 1;
    RandomYSwap := 0.001;
    CFG.YSwap := 0.0001;
    RandomWavePart := 360;
    RandomWavePartF := 360;
    CFG.WavePart := 360;
    HorPxStep:=2.0/CFG.WavePart;
    Intensity := 0.2;
    Random3DRotX := Random(11);
    Random3DRotXF := CFG._3DRotX;
    Random3DRotY := Random(11);
    Random3DRotYF := CFG._3DRotY;
    Random3DRotZ := Random(11);
    Random3DRotZF := CFG._3DRotZ;
    CFG._3DRot := true;
    for ii:=0 to 100 do RandomShow;
  end;
end;

{==============================================================================}


function TWaves.SinArray(inDeg: integer): single;
begin
  if inDeg>=0 then SinArray:=MySinA[inDeg mod 360]
          else SinArray:=-MySinA[(-inDeg) mod 360]
end;

function TWaves.CosArray(inDeg: integer): single;
begin
  if inDeg>=0 then CosArray:=MyCosA[inDeg mod 360]
          else CosArray:=-MyCosA[(-inDeg) mod 360]
end;

procedure TWaves.AutoInit;
var ii: integer;
begin
  for ii:=0 to 359 do begin
    MySinA[ii]:=sin(degtorad(ii));
    MyCosA[ii]:=cos(degtorad(ii))
  end;
end;




initialization

begin
  Wave.AutoInit
end;

end.
