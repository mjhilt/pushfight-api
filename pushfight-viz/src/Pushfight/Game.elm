module Pushfight.Game exposing (Game, viewPushfight)
import Pushfight.Board exposing (Board)
import Pushfight.GameStage exposing (GameStage)
import Pushfight.Color exposing (Color)
import Pushfight.Orientation exposing (Orientation)
import Pushfight.DragState exposing (DragState)


type alias Game =
	{ board: Board
	, gameStage: GameStage
	, color: Color
	, moves: List (Int, Int)
	, dragState: DragState
	}

type Msg
    = DragAt Position
    | DragEnd Position
    | MouseDownAt (Float, Float)
    --| EndTurn
    | Undo
    --| ToggleEndTurnOnPush Bool
    --| RotateOrientationCCW

--mouseSubsrciptions : DragState -> Sub Msg
--mouseSubsrciptions model =
--    case model.dragState of
--        NotDragging ->
--            Browser.Events.onMouseDown (Decode.map DragAt position)
--        _ ->
--            Sub.batch
--                [ Browser.Events.onMouseMove (Decode.map DragAt position)
--                , Browser.Events.onMouseUp (Decode.map DragEnd position)
--                ]


-- helpers


sign : Int -> Int
sign n =
    if n < 0 then
        -1
    else
        1


-- view

boardColor =
    "#BD632F"

pieceColorWhite =
    "#FFFAFA"

pieceColorBlack =
    "#19180A"

pieceMovingColor =
    "#D8AC8D"

anchorColor =
    "#A4243B"

drawBoardSquare : Int -> (Int -> Int -> (Int, Int)) -> Int -> Int -> Svg Msg
drawBoardSquare size rotateXY y x =
    let
        (xr, yr) =
            rotateXY x y
        (color, extraStyles) =
            if isInBoard x y then
                (boardColor, [Attributes.strokeWidth "1", Attributes.stroke "black"])
            else
                 ("#aaaaaa", [Attributes.fillOpacity "0"])

    in
        Svg.rect (
            List.append extraStyles
                [ Attributes.x <| String.fromInt (size * xr)
                , Attributes.y <| String.fromInt (size * yr)
                , Attributes.width <| String.fromInt size
                , Attributes.height <| String.fromInt size
                , Attributes.fill color
                ]
            ) []


drawRow : Orientation -> Int -> List Int -> Int -> List (Svg Msg)
drawRow orientation size xs y =
    List.map (drawBoardSquare size (rmapXY orientation) y) xs


drawBoard : Orientation -> Int -> List (Svg Msg)
drawBoard orientation size =
    List.map (drawRow orientation size (List.range 0 9)) (List.range 0 3)
    |> List.concat


drawPusher : Int -> Int -> Int -> String -> String -> List (Svg Msg)
drawPusher size x y color accentColor =
    let
        (posx, posy, fsize) =
            (toFloat (size * x), toFloat (size * y), toFloat size)
    in
        [ Svg.rect
            [ Attributes.fill accentColor
            , Attributes.x <| String.fromInt <| round (posx + fsize * 0.02)
            , Attributes.y <| String.fromInt <| round (posy + fsize * 0.02)
            , Attributes.width <| String.fromInt <| round (fsize * 0.96)
            , Attributes.height <| String.fromInt <| round (fsize * 0.96)
            ]
            []
        , Svg.rect
            [ Attributes.fill color
            , Attributes.x <| String.fromInt <| round (posx + fsize * 0.05)
            , Attributes.y <| String.fromInt <| round (posy + fsize * 0.05)
            , Attributes.width <| String.fromInt <| round (fsize * 0.9)
            , Attributes.height <| String.fromInt <| round (fsize * 0.9)
            , Touch.onStart ( \e -> MouseDownAt (x*size + size//2 |> toFloat, y*size + size//2 |> toFloat) )
            ]
            []
        ]


drawMover : Int -> Int -> Int -> String -> String -> List (Svg Msg)
drawMover size x y color accentColor =
    let
        (posx, posy, fsize) =
            (toFloat (size * x), toFloat (size * y), toFloat size)
    in
        [ Svg.circle
            [ Attributes.fill accentColor
            , Attributes.cx <| String.fromInt <| round (posx + (fsize / 2.0))
            , Attributes.cy <| String.fromInt <| round (posy + (fsize / 2.0))
            , Attributes.r <| String.fromInt <| round (fsize / 2.0)
            ]
            []
        , Svg.circle
            [ Attributes.fill color
            , Attributes.cx <| String.fromInt <| round (posx + (fsize / 2.0))
            , Attributes.cy <| String.fromInt <| round (posy + (fsize / 2.0))
            , Attributes.r <| String.fromInt <| round ((fsize * 0.95) / 2.0)
            , Touch.onStart ( \e -> MouseDownAt (x*size + size//2 |> toFloat, y*size + size//2 |> toFloat) )
            ]
            []
        ]


drawAnchor : Int -> Int -> Int -> List (Svg Msg)
drawAnchor size x y =
    let
        (posx, posy, fsize) =
            (toFloat (size * x), toFloat (size * y), toFloat size)
    in
        [
            Svg.circle
                [ Attributes.fill anchorColor
                , Attributes.cx <| String.fromInt <| round (posx + (fsize / 2.0))
                , Attributes.cy <| String.fromInt <| round (posy + (fsize / 2.0))
                , Attributes.r <| String.fromInt <| round (fsize / 4.0)
                ]
                []
        ]
