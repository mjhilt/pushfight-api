module Pushfight.Game exposing (Model, Msg, OutMsg(..), init, subscriptions, update, view)
import Debug

import Html
import Html.Events
import Html.Events.Extra.Mouse as Mouse
import Html.Events.Extra.Touch as Touch
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
    , turn : Int
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
    , turn = 1
    }



-- update


type Msg
    = DragMsg DragState.Msg
    | EndTurn
    | Undo
    | RequestTakeBack
    | OfferDraw
    | AcceptTakeback
    | AcceptDraw
    | Resign


type OutMsg
    = SendNoOp
    | SendTurnEnded ( Board.Board, List Move, GameStage )
    | SendUpdatedBoard ( Board.Board, List Move )
    --| SendRequestTakeback
    --| SendOfferDraw
    | SendRequest Request
    | SendAcceptDraw
    | SendAcceptTakeback
    | SendResign



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

lastMovePush : List Move -> Board.Board -> Bool
lastMovePush moves board =
    let
        newBoard = (doMoves moves board)
    in
    case (moves |> List.reverse |> List.head, newBoard) of
        (Just lastMove, Just b) ->
            Board.anchorAt b lastMove.to

        _ ->
            False

handleEndTurn : List Move -> Board.Board -> GameStage -> Color -> Maybe ( Board.Board, GameStage )
handleEndTurn moves board gameStage color =
    let
        newBoard = (doMoves moves board)

        pieceOutOfBounds =
            Board.pieceOutOfBounds board

        moveLen =
            List.length moves
        _ =
            Debug.log "1" ( (moveLen > 0) && (moveLen <= 3) )
        _ =
            Debug.log "2" color
        --_ =
        --    Debug.log "3" lastMovePush
        _ =
            Debug.log "4" pieceOutOfBounds
    in
    -- TODO check side on setup
    case ( newBoard, gameStage, ( ( (moveLen > 0) && (moveLen <= 3), color ), ( lastMovePush moves board, pieceOutOfBounds ) ) ) of
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


getDragFromToIX : Orientation.Orientation -> DragState.Drag -> Int -> Move
getDragFromToIX orientation drag gridSize =
    let
        mapXY =
            Orientation.mapXY orientation

        ( fromX, fromY ) =
            mapXY (drag.from.x // gridSize) (drag.from.y // gridSize)

        ( toX, toY ) =
            mapXY (drag.to.x // gridSize) (drag.to.y // gridSize)

        from =
            fromX + 10 * fromY

        to =
            toX + 10 * toY
    in
    { from = from, to = to }


handleDrag : Model -> DragState.Drag -> DragState.Model -> Model
handleDrag model drag dragState =
    let
        newMove =
            getDragFromToIX model.orientation drag model.gridSize

        currentBoard = doMoves model.moves model.board |> Maybe.withDefault model.board
        newMoves =
            List.append model.moves [ newMove ]
        newBoard = doMoves newMoves model.board |> Maybe.withDefault model.board

        --case List.reverse model.moves of
        --    --[] ->
        --    --    [ newMove ]
        --    --lastMove :: otherMoves ->
        --        --if lastMove.to == newMove.from && not (Board.isPiece board newMove.to) then
        --            --List.append (List.reverse otherMoves) [ newMove ]
        --        --else
        --        List.append model.moves [ newMove ]
        isValidColor =
            (Board.isWhitePiece currentBoard newMove.from && (model.color == White)) || (Board.isBlackPiece currentBoard newMove.from && (model.color == Black))
        moveInBounds =
            Board.isInBoard newMove.to
        validMove =
            case model.gameStage of
                WhiteSetup ->
                    Board.validWhiteSetup newBoard
                BlackSetup ->
                    Board.validBlackSetup newBoard
                _ ->
                    True
        --couldEndTurn =
        --    handleEndTurn moves board gameStage color
    in
    case ( isValidColor && validMove && moveInBounds, doMoves newMoves model.board ) of
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
                    let
                        newModel = handleDrag model drag dragState
                        newBoard = doMoves newModel.moves newModel.board
                        outMsg =
                            case newBoard of
                                Just board ->
                                    --if newModel.board == board then
                                    --    Debug.log "No op I guess" SendNoOp
                                    --else
                                    --    --Debug.log "Updating board" (SendUpdatedBoard newModel.board newModel.moves board)
                                    Debug.log "Updating board" (SendUpdatedBoard (board, newModel.moves) )
                                Nothing ->
                                    SendNoOp
                    in
                    (newModel , outMsg )

                Nothing ->
                    ( { model | dragState = dragState }, SendNoOp )

        EndTurn ->
            case handleEndTurn model.moves model.board model.gameStage model.color of
                Just ( board, gameStage ) ->
                    --({model|board=board,gameStage=gameStage}, SendTurnEnded(board, gameStage))
                    ( model, SendTurnEnded ( board, model.moves, gameStage ) )

                Nothing ->
                    let
                        _ =
                            Debug.log "Failed to end turn" ()
                    in
                    ( model, SendNoOp )

        Undo ->
            let
                newModel =
                    undoMove model
            in
            ( undoMove model, SendUpdatedBoard (newModel.board, newModel.moves) )

        RequestTakeBack ->
            ( model, SendRequest (TakebackRequested model.color))

        OfferDraw ->
            ( model, SendRequest (DrawOffered model.color))

        AcceptDraw ->
            ( { model | gameStage = Draw }, SendAcceptDraw )

        AcceptTakeback ->
            ( model, SendAcceptTakeback )

        Resign ->
            --let
            --    gs =
            --        case model.color of
            --            White ->
            --                BlackWon
            --            Black ->
            --                WhiteWon
            --in
            --({model| gameStage = gs }, SendResign)
            ( model, SendResign )



-- subscriptions


subscriptions : Sub Msg
subscriptions =
    Sub.none



--Sub.map DragMsg DragState.subscriptions
-- view


view : Model -> Html.Html Msg
view model =
    let
        rmapXY =
            Orientation.rmapXY model.orientation

        moveBoard =
            doMoves model.moves model.board
                |> Maybe.withDefault model.board

        piecesViz =
            List.foldl (++)
                []
                [ drawPiece model.gridSize rmapXY True True moveBoard.wp1
                , drawPiece model.gridSize rmapXY True True moveBoard.wp2
                , drawPiece model.gridSize rmapXY True True moveBoard.wp3
                , drawPiece model.gridSize rmapXY True False moveBoard.wm1
                , drawPiece model.gridSize rmapXY True False moveBoard.wm2
                , drawPiece model.gridSize rmapXY False True moveBoard.bp1
                , drawPiece model.gridSize rmapXY False True moveBoard.bp2
                , drawPiece model.gridSize rmapXY False True moveBoard.bp3
                , drawPiece model.gridSize rmapXY False False moveBoard.bm1
                , drawPiece model.gridSize rmapXY False False moveBoard.bm2
                ]

        anchorViz =
            case moveBoard.anchor of
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

        boardViz =
            drawBoard model.gridSize rmapXY

        width =
            String.fromInt (4 * model.gridSize)

        height =
            String.fromInt (10 * model.gridSize)

        title =
            case model.gameStage of
                WaitingForPlayers ->
                    "Waiting For Players"

                WhiteSetup ->
                    "White Setup"

                BlackSetup ->
                    "Black Setup"

                WhiteTurn ->
                    "White Turn, " ++ String.fromInt (2 - List.length model.moves) ++ " moves left"

                BlackTurn ->
                    "Black Turn, " ++ String.fromInt (2 - List.length model.moves) ++ " moves left"

                WhiteWon ->
                    "White Won - Game Over"

                BlackWon ->
                    "Black Won - Game Over"

                Draw ->
                    "Draw - Game Over"

        eventHelper msg e =
            let
                ( x, y ) =
                    e.offsetPos
            in
            msg { x = floor x, y = floor y } |> DragMsg

        requestView =
            let
                noView = Html.div [] []
            in
            case model.request of
                NoRequest ->
                    noView
                TakebackRequested c ->
                    if c /= model.color then
                        Html.div [] [ Html.button [ Html.Events.onClick AcceptTakeback ] [ Html.text "Accept Takeback" ] ]
                    else
                        noView

                DrawOffered c ->
                    if c /= model.color then
                        Html.div [] [ Html.button [ Html.Events.onClick AcceptDraw ] [ Html.text "Accept Draw" ] ]
                    else
                        noView
    in
    Html.div []
        [ Html.text title
        , Svg.svg
            [ Svg.Attributes.width width
            , Svg.Attributes.height height
            , Svg.Attributes.viewBox <| "0 0 " ++ width ++ " " ++ height

            --, Mouse.onDown ( \event -> (DragMsg (DragState.MouseDown {x=round event.offsetPos.x, y=round event.offsetPos.y})) )
            , Mouse.onMove (eventHelper DragState.MouseMove)
            , Mouse.onDown (eventHelper DragState.MouseDown)
            , Mouse.onUp (eventHelper DragState.MouseUp)

            --, Touch.onStart (eventHelper DragState.MouseDown)
            --, Touch.onEnd (eventHelper DragState.MouseUp)
            ]
            (List.concat
                [ boardViz
                , piecesViz
                , anchorViz
                ]
            )
        , Html.div []
            [ Html.button [ Html.Events.onClick EndTurn ] [ Html.text "End Turn" ]
            , Html.button [ Html.Events.onClick Undo ] [ Html.text "Undo" ]
            ]
        , Html.div []
            [ Html.button [ Html.Events.onClick RequestTakeBack ] [ Html.text "Request Takeback" ]
            , Html.button [ Html.Events.onClick OfferDraw ] [ Html.text "Offer Draw" ]
            , Html.button [ Html.Events.onClick Resign ] [ Html.text "Resign" ]
            ]
        , requestView
        ]


drawPiece : Int -> (Int -> Int -> ( Int, Int )) -> Bool -> Bool -> Int -> List (Svg Msg)
drawPiece size rmapXY isWhite isPusher ix =
    let
        ( x, y ) =
            Board.ixToXY ix

        ( rx, ry ) =
            rmapXY x y

        ( color, accentColor ) =
            if isWhite then
                ( pieceColorWhite, pieceColorBlack )

            else
                ( pieceColorBlack, pieceColorWhite )
    in
    if isPusher then
        drawPusher size rx ry color accentColor

    else
        drawMover size rx ry color accentColor


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

            --, 37
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

        --, Mouse.onDown ( \e -> DragState.MouseDown {x=x*size + size//2, y=y*size + size//2} |> DragMsg)
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
