module Pushfight.Game exposing (Model, Msg, OutMsg(..), init, subscriptions, update, view)

import Html
import Pushfight.Board as Board
import Pushfight.Color exposing (Color(..))
import Pushfight.DragState as DragState
import Pushfight.GameStage exposing (GameStage(..))
import Pushfight.Move exposing (Move)
import Pushfight.Orientation as Orientation
import Pushfight.Request exposing (Request(..))
import Svg exposing (Svg)
import Svg.Attributes



-- model


type alias Model =
    { board : Board.Board
    , gameStage : GameStage
    , color : Color
    , orientation : Orientation.Orientation
    , moves : List Move
    , dragState : DragState.Model
    , gridSize : Int
    , request : Request
    }



-- init


init : Board.Board -> GameStage -> Color -> List Move -> Int -> Request -> Model
init board gameStage color moves gridSize request =
    let
        orientation =
            case color of
                White ->
                    Orientation.Ninety

                Black ->
                    Orientation.TwoSeventy
    in
    { board = board
    , gameStage = gameStage
    , color = color
    , moves = moves
    , orientation = orientation
    , dragState = DragState.init
    , gridSize = gridSize
    , request = request
    }



-- update


type Msg
    = DragMsg DragState.Msg
    | EndTurn
    | Undo
    | AskForTakeBack
    | OfferDraw
    | AcceptTakeback
    | AcceptDraw


type OutMsg
    = SendNoOp
    | SendTurnEnded ( Board.Board, GameStage )
    | SendRequestTakeback
    | SendOfferDraw
    | SendAcceptDraw
    | SendAcceptTakeback



--type OutMsg
--    = NoOp
--    | RequestDraw
--    | AcceptDraw
--    | RequestTakeback
--    | AcceptTakeback
--    | BoardUpdated


undoMove : Model -> Model
undoMove model =
    let
        revMoves =
            model.moves
                |> List.reverse
                |> List.tail

        moves =
            case revMoves of
                Just ms ->
                    List.reverse ms

                Nothing ->
                    []
    in
    { model | moves = moves }


doMoves : List Move -> Board.Board -> Maybe Board.Board
doMoves moves board =
    case moves of
        [] ->
            Just board

        m :: ms ->
            case Board.move board m.from m.to of
                Just b ->
                    doMoves ms b

                Nothing ->
                    Nothing



--Maybe.map
--|> doMoves ms
--|> Board.move board m


handleEndTurn : List Move -> Board.Board -> GameStage -> Color -> Maybe ( Board.Board, GameStage )
handleEndTurn moves board gameStage color =
    --case List.reverse moves of
    --    [] ->
    --        Nothing
    --    [lastMove::_] ->
    let
        newBoard =
            doMoves moves board

        --lastMove =
        lastMovePush =
            case moves |> List.reverse |> List.head of
                Just lastMove ->
                    Board.anchorAt board lastMove.to

                Nothing ->
                    False

        --|>
        --|>
        --Maybe.map
        --|> Board.anchorAt board
        --|> lastMove.to
        pieceOutOfBounds =
            Board.pieceOutOfBounds board

        moveLen =
            List.length moves
    in
    case ( newBoard, gameStage, ( ( (moveLen > 0) && (moveLen <= 3), color ), ( lastMovePush, pieceOutOfBounds ) ) ) of
        ( Just b, WhiteSetup, ( ( _, White ), ( False, False ) ) ) ->
            Just ( b, BlackSetup )

        ( Just b, BlackSetup, ( ( _, Black ), ( False, False ) ) ) ->
            Just ( b, WhiteTurn )

        ( Just b, WhiteTurn, ( ( True, White ), ( True, False ) ) ) ->
            Just ( b, BlackTurn )

        ( Just b, BlackTurn, ( ( True, Black ), ( True, False ) ) ) ->
            Just ( b, WhiteTurn )

        ( Just b, WhiteTurn, ( ( True, White ), ( True, True ) ) ) ->
            Just ( b, WhiteWon )

        ( Just b, BlackTurn, ( ( True, Black ), ( True, True ) ) ) ->
            Just ( b, BlackWon )

        _ ->
            Nothing


handleDrag : Model -> DragState.Drag -> DragState.Model -> Model
handleDrag model drag dragState =
    let
        --dx = (to.x - from.x)//model.gridSize
        --dy = (to.y - from.y)//model.gridSize
        mapXY =
            Orientation.mapXY model.orientation

        ( fromX, fromY ) =
            mapXY (drag.from.x // model.gridSize) (drag.from.y // model.gridSize)

        ( toX, toY ) =
            mapXY (drag.to.x // model.gridSize) (drag.to.y // model.gridSize)

        from =
            fromX + 10 * fromY

        to =
            toX + 10 * toY

        newMoves =
            case List.reverse model.moves of
                [] ->
                    [ { from = from, to = to } ]

                lastMove :: otherMoves ->
                    if lastMove.to == from then
                        List.append (List.reverse otherMoves) [ { from = lastMove.from, to = to } ]

                    else
                        List.append model.moves [ { from = from, to = to } ]

        isValid =
            (Board.isWhitePiece model.board from && (model.color == White)) || (Board.isBlackPiece model.board from && (model.color == Black))
    in
    case ( isValid, doMoves newMoves model.board ) of
        ( True, Just _ ) ->
            { model | moves = newMoves, dragState = dragState }

        _ ->
            { model | dragState = dragState }


update : Msg -> Model -> ( Model, OutMsg )
update msg model =
    case msg of
        DragMsg dragMsg ->
            let
                ( dragState, finishedDrag ) =
                    DragState.update dragMsg model.dragState
            in
            case finishedDrag of
                Just drag ->
                    --let
                    --    newModel =
                    --in
                    --(newModel, NoOp)
                    ( handleDrag model drag dragState, SendNoOp )

                Nothing ->
                    ( { model | dragState = dragState }, SendNoOp )

        EndTurn ->
            case handleEndTurn model.moves model.board model.gameStage model.color of
                Just ( board, gameStage ) ->
                    --({model|board=board,gameStage=gameStage}, SendTurnEnded(board, gameStage))
                    ( model, SendTurnEnded ( board, gameStage ) )

                Nothing ->
                    ( model, SendNoOp )

        Undo ->
            ( undoMove model, SendNoOp )

        AskForTakeBack ->
            ( { model | request = TakebackRequested }, SendRequestTakeback )

        OfferDraw ->
            ( { model | request = DrawOffered }, SendOfferDraw )

        AcceptDraw ->
            ( { model | gameStage = Draw }, SendAcceptDraw )

        AcceptTakeback ->
            ( model, SendAcceptTakeback )



-- subscriptions


subscriptions : Sub Msg
subscriptions =
    Sub.map DragMsg DragState.subscriptions



-- view


view : Model -> Html.Html Msg
view model =
    let
        rmapXY =
            Orientation.rmapXY model.orientation

        pieces =
            List.foldl (++)
                []
                [ drawPiece model.gridSize rmapXY True True model.board.wp1
                , drawPiece model.gridSize rmapXY True True model.board.wp2
                , drawPiece model.gridSize rmapXY True True model.board.wp3
                , drawPiece model.gridSize rmapXY True False model.board.wm1
                , drawPiece model.gridSize rmapXY True False model.board.wm2
                , drawPiece model.gridSize rmapXY False True model.board.bp1
                , drawPiece model.gridSize rmapXY False True model.board.bp2
                , drawPiece model.gridSize rmapXY False True model.board.bp3
                , drawPiece model.gridSize rmapXY False False model.board.bm1
                , drawPiece model.gridSize rmapXY False False model.board.bm2
                ]

        anchor =
            case model.board.anchor of
                Just a ->
                    let
                        ( x, y ) =
                            Board.ixToXY a

                        ( xr, yr ) =
                            rmapXY x y
                    in
                    drawAnchor model.gridSize xr yr

                Nothing ->
                    []

        board =
            drawBoard model.gridSize rmapXY

        width =
            String.fromInt (4 * model.gridSize)

        height =
            String.fromInt (10 * model.gridSize)

        title =
            case model.gameStage of
                WhiteSetup ->
                    "WhiteSetup"

                BlackSetup ->
                    "BlackSetup"

                WhiteTurn ->
                    "WhiteTurn, " ++ String.fromInt (2 - List.length model.moves) ++ " moves left"

                BlackTurn ->
                    "BlackTurn, " ++ String.fromInt (2 - List.length model.moves) ++ " moves left"

                WhiteWon ->
                    "WhiteWon"

                BlackWon ->
                    "BlackWon"

                Draw ->
                    "Draw"
    in
    Html.div []
        [ Html.text title
        , Svg.svg
            [ Svg.Attributes.width width
            , Svg.Attributes.height height
            , Svg.Attributes.viewBox <| "0 0 " ++ width ++ " " ++ height
            ]
            (List.concat
                [ board
                , pieces
                , anchor
                ]
            )
        ]


drawPiece : Int -> (Int -> Int -> ( Int, Int )) -> Bool -> Bool -> Int -> List (Svg Msg)
drawPiece size rmapXY isWhite isPusher ix =
    let
        ( x, y ) =
            Board.ixToXY ix

        ( color, accentColor ) =
            if isWhite then
                ( pieceColorWhite, pieceColorBlack )

            else
                ( pieceColorBlack, pieceColorWhite )
    in
    if isPusher then
        drawPusher size x y color accentColor

    else
        drawMover size x y color accentColor


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


drawBoardSquare size x y =
    let
        ( color, extraStyles ) =
            ( boardColor, [ Svg.Attributes.strokeWidth "1", Svg.Attributes.stroke "black" ] )
    in
    Svg.rect
        (List.append extraStyles
            [ Svg.Attributes.x <| String.fromInt (size * x)
            , Svg.Attributes.y <| String.fromInt (size * y)
            , Svg.Attributes.width <| String.fromInt size
            , Svg.Attributes.height <| String.fromInt size
            , Svg.Attributes.fill color
            ]
        )
        []


drawBoard : Int -> (Int -> Int -> ( Int, Int )) -> List (Svg Msg)
drawBoard size rotateXY =
    let
        boardIxs =
            [ 3
            , 4
            , 5
            , 6
            , 7
            , 11
            , 12
            , 13
            , 14
            , 15
            , 16
            , 17
            , 18
            , 21
            , 22
            , 23
            , 24
            , 25
            , 26
            , 27
            , 28
            , 32
            , 33
            , 34
            , 35
            , 36
            , 37
            ]

        boardXY =
            List.map Board.ixToXY boardIxs

        ( xs, ys ) =
            List.unzip boardXY

        boardRXY =
            List.map2 rotateXY xs ys

        ( xrs, yrs ) =
            List.unzip boardRXY
    in
    List.map2 (drawBoardSquare size) xrs yrs


drawPusher : Int -> Int -> Int -> String -> String -> List (Svg Msg)
drawPusher size x y color accentColor =
    let
        ( posx, posy, fsize ) =
            ( toFloat (size * x), toFloat (size * y), toFloat size )
    in
    [ Svg.rect
        [ Svg.Attributes.fill accentColor
        , Svg.Attributes.x <| String.fromInt <| round (posx + fsize * 0.02)
        , Svg.Attributes.y <| String.fromInt <| round (posy + fsize * 0.02)
        , Svg.Attributes.width <| String.fromInt <| round (fsize * 0.96)
        , Svg.Attributes.height <| String.fromInt <| round (fsize * 0.96)
        ]
        []
    , Svg.rect
        [ Svg.Attributes.fill color
        , Svg.Attributes.x <| String.fromInt <| round (posx + fsize * 0.05)
        , Svg.Attributes.y <| String.fromInt <| round (posy + fsize * 0.05)
        , Svg.Attributes.width <| String.fromInt <| round (fsize * 0.9)
        , Svg.Attributes.height <| String.fromInt <| round (fsize * 0.9)

        --, Touch.onStart ( \e -> MouseDownAt (x*size + size//2 |> toFloat, y*size + size//2 |> toFloat) )
        ]
        []
    ]


drawMover : Int -> Int -> Int -> String -> String -> List (Svg Msg)
drawMover size x y color accentColor =
    let
        ( posx, posy, fsize ) =
            ( toFloat (size * x), toFloat (size * y), toFloat size )
    in
    [ Svg.circle
        [ Svg.Attributes.fill accentColor
        , Svg.Attributes.cx <| String.fromInt <| round (posx + (fsize / 2.0))
        , Svg.Attributes.cy <| String.fromInt <| round (posy + (fsize / 2.0))
        , Svg.Attributes.r <| String.fromInt <| round (fsize / 2.0)
        ]
        []
    , Svg.circle
        [ Svg.Attributes.fill color
        , Svg.Attributes.cx <| String.fromInt <| round (posx + (fsize / 2.0))
        , Svg.Attributes.cy <| String.fromInt <| round (posy + (fsize / 2.0))
        , Svg.Attributes.r <| String.fromInt <| round ((fsize * 0.95) / 2.0)

        --, Touch.onStart ( \e -> MouseDownAt (x*size + size//2 |> toFloat, y*size + size//2 |> toFloat) )
        ]
        []
    ]


drawAnchor : Int -> Int -> Int -> List (Svg Msg)
drawAnchor size x y =
    let
        ( posx, posy, fsize ) =
            ( toFloat (size * x), toFloat (size * y), toFloat size )
    in
    [ Svg.circle
        [ Svg.Attributes.fill anchorColor
        , Svg.Attributes.cx <| String.fromInt <| round (posx + (fsize / 2.0))
        , Svg.Attributes.cy <| String.fromInt <| round (posy + (fsize / 2.0))
        , Svg.Attributes.r <| String.fromInt <| round (fsize / 4.0)
        ]
        []
    ]



-- TODO
--drawRails : Int -> Orientation -> List (Svg Msg)
--drawRails size orientation =
