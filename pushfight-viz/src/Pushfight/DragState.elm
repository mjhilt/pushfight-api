module Pushfight.DragState exposing (MousePosition, DragState, DragMsg, dragUpdate, dragSubscriptions)

import Browser.Events
import Json.Decode as Decode exposing (Decoder)
--import Pushfight.Orientation exposing (Orientation, rmapXY, mapXY)

type alias MousePosition =
    { x: Int
    , y: Int
    }

type alias Drag =
    { from: MousePosition
    , to: MousePosition
    }

type DragState
    = NotDragging
    | Dragging Drag

type DragMsg
 = MouseDown MousePosition
 | MouseUp MousePosition
 | MouseMove MousePosition

-- init

init: DragState
init =
    NotDragging

-- update

dragUpdate: DragState -> DragMsg -> (DragState, Maybe Drag)
dragUpdate model msg =
    case (model, msg) of
        (NotDragging, MouseDown pos) ->
            --let
            --    drag = {from=pos, to=pos}
            --in
            (Dragging {from=pos, to=pos}, Nothing)
        (Dragging drag, MouseUp pos) ->
            (NotDragging, Just {drag|to=pos})
        (Dragging drag, MouseMove pos) ->
            (Dragging {drag| to=pos}, Nothing)
        (ds, _) ->
            (ds, Nothing)

--type alias PositionKey = (Int, Int)


--getGridPos : Orientation -> Position -> Maybe MouseDrag -> Int -> PositionKey
--getGridPos orientation {x, y} mouseDrag gridSize =
--    --let
--    --    (xx, yy) =
--    case mouseDrag of
--        Just {dragStart, dragCurrent} ->
--            let
--                dxpx =
--                    (dragCurrent.x - dragStart.x)
--                dypx =
--                    (dragCurrent.y - dragStart.y)
--                dx = ( (sign dxpx) * (abs dxpx + (gridSize // 2)) ) // gridSize
--                dy = ( (sign dypx) * (abs dypx + (gridSize // 2)) ) // gridSize
--                (xr, yr) = Draw.rmapXY orientation x y
--                --(dxx)
--            in
--                Draw.mapXY orientation (xr  + dx) (yr  + dy)
--        Nothing ->
--            ( x, y )

--handleDrag : MouseDrag -> Position -> Model
--handleDrag dragState mousePos =
--    case dragState of
--        NotDragging ->
--          Dragging { from: mousePos, to: mousePos}
--        Dragging {from, _} =
--          Dragging {from: from, to: mousePos}


--handleDragEnd : MouseDrag -> Position -> (MouseDrag, Drag)
--handleDragEnd mouseDrag =
--  case NotDragging
--    case model.dragState of
--        DraggingPiece {piece, from, mouseDrag} ->
--            let
--                (toX, toY) =
--                    getGridPos model.orientation from mouseDrag model.gridSize
--                --(fromX, fromY) =
--                --    Draw.mapXY model.orientation from.x from.y
--                updatedTurn =
--                    move model (from.x, from.y) (toX, toY)
--                updatedModel =
--                    { model | currentTurn = updatedTurn, dragState = NotDragging}
--            in
--                if model.endTurnOnPush then
--                    case updatedTurn.push of
--                        Just push ->
--                            let
--                                (newModel, _, _) = update EndTurn updatedModel
--                            in
--                                (newModel, True)
--                        Nothing  ->
--                            (updatedModel, False)
--                else
--                    (updatedModel, False)
--        _ ->
--            ( { model | dragState = NotDragging }, False )


--handleClick : Model -> PositionKey -> Model
--handleClick model (xu, yu) =
--    let
--        (x, y) =
--            Draw.mapXY model.orientation xu yu
--    in
--    case Dict.get (x, y) (getBoard model).pieces of
--        Just piece ->
--            case model.dragState of
--                NotDragging ->
--                    let
--                        lastMovedPiece =
--                            MovingPiece piece (Position x y) Nothing
--                    in
--                        { model | dragState = DraggingPiece lastMovedPiece }
--                DraggingNothing previousMouseDrag ->
--                    let
--                        lastMovedPiece =
--                            MovingPiece piece (Position x y) (Just previousMouseDrag)
--                    in
--                        { model | dragState = DraggingPiece lastMovedPiece }
--                _ ->
--                    model

--        Nothing ->
--            model

-- subscription

decodePosition : Decode.Decoder MousePosition
decodePosition =
    Decode.map2 MousePosition
        (Decode.field "pageX" Decode.int)
        (Decode.field "pageY" Decode.int)

dragSubscriptions : Sub DragMsg
dragSubscriptions =
    Sub.batch
        [ Browser.Events.onMouseDown (Decode.map MouseDown decodePosition)
        , Browser.Events.onMouseMove (Decode.map MouseMove decodePosition)
        , Browser.Events.onMouseUp (Decode.map MouseUp decodePosition)
        ]


-- helpers


--sign : Int -> Int
--sign n =
--    if n < 0 then
--        -1
--    else
--        1
