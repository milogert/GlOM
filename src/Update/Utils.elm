module Update.Utils exposing (addUpgrade, addVehicle, addWeapon, deleteVehicle, deleteWeapon, deleteUpgrade, setTmpVehicleType, updateActivated, updateGear, updateCrew, updateEquipment, updateHull, updateNotes)

import Debug exposing (log)

import Model.Model exposing (..)
import Model.Vehicles exposing (..)
import Model.Weapons exposing (..)
import Model.Upgrades exposing (..)


(!!) : Int -> List a -> Maybe a
(!!) n xs  = 
    log "to get" (List.head <| List.drop n xs)


addVehicle : Model -> ( Model, Cmd Msg )
addVehicle model =
    case model.tmpVehicle of
        Just vehicleTmp ->
            let
                oldl =
                    model.vehicles
            in
            case ( vehicleTmp.vtype, vehicleTmp.name ) of
                ( _, "" ) ->
                    { model | error = VehicleNameError :: model.error } ! []

                ( _, _ ) ->
                    { model
                        | view = Overview
                        , vehicles = oldl ++ [ { vehicleTmp | id = List.length oldl } ]
                        , tmpVehicle = Nothing
                        , error = []
                    }
                        ! []
        Nothing ->
            model ! []


addWeapon : Model -> Vehicle -> ( Model, Cmd Msg )
addWeapon model v =
    case model.tmpWeapon of
        Just weaponTmp ->
            let
                weaponList =
                    v.weapons ++ [ { weaponTmp | id = List.length v.weapons } ]

                pre =
                    List.take v.id model.vehicles

                post =
                    List.drop (v.id + 1) model.vehicles

                vehicleNew =
                    { v | weapons = weaponList }

                newvehicles =
                    pre ++ vehicleNew :: post
            in
            { model | view = Details vehicleNew , error = [], vehicles = newvehicles } ! []
        Nothing ->
            model ! []


addUpgrade : Model -> Vehicle -> ( Model, Cmd Msg )
addUpgrade model v =
    case model.tmpUpgrade of
        Just upgradeTmp ->
            let
                upgradeList =
                    v.upgrades ++ [ { upgradeTmp | id = List.length v.upgrades } ]

                pre =
                    List.take v.id model.vehicles

                post =
                    List.drop (v.id + 1) model.vehicles

                vehicleNew =
                    { v | upgrades = upgradeList }

                newvehicles =
                    pre ++ vehicleNew :: post
            in
            case upgradeTmp.name of
                "" ->
                    { model | error = [ UpgradeTypeError ] } ! []

                _ ->
                    { model | view = Details vehicleNew, error = [], vehicles = newvehicles } ! []

        Nothing ->
            model ! []


setTmpVehicleType : Model -> String -> ( Model, Cmd Msg )
setTmpVehicleType model vtstr =
    let
        maybeVType =
            strToVT vtstr

    in
    case maybeVType of
        Nothing ->
            model ! []

        Just vtype ->
            let
                name = case model.tmpVehicle of
                    Just v -> v.name
                    Nothing -> ""

                gear =
                    GearTracker 0 (typeToGearMax vtype)

                handling =
                    typeToHandling vtype

                hull =
                    HullHolder 0 (typeToHullMax vtype)

                crew =
                    typeToCrewMax vtype

                equipment =
                    typeToEquipmentMax vtype

                weight =
                    typeToWeight vtype

                weapons = case model.tmpVehicle of
                    Just v -> v.weapons
                    Nothing -> []

                upgrades = case model.tmpVehicle of
                    Just v -> v.upgrades
                    Nothing -> []

                notes = case model.tmpVehicle of
                    Just v -> v.notes
                    Nothing -> ""


                cost =
                    typeToCost vtype

                newtv =
                    Vehicle
                        name
                        vtype
                        gear
                        handling
                        hull
                        crew
                        equipment
                        weight
                        False
                        weapons
                        upgrades
                        notes
                        cost
                        -1
            in
            { model | tmpVehicle = Just newtv } ! []


updateActivated : Model -> Vehicle -> Bool -> ( Model, Cmd Msg )
updateActivated model v activated =
    let
        pre =
            List.take v.id model.vehicles

        nv =
            { v | activated = activated }

        post =
            List.drop (v.id + 1) model.vehicles
    in
    { model | vehicles = pre ++ nv :: post } ! []


updateGear : Model -> Vehicle -> Int -> ( Model, Cmd Msg )
updateGear model v newGear =
    let
        newGearTracker =
            GearTracker newGear v.gear.max

        vehiclesList =
            joinAround v.id { v | gear = newGearTracker } model.vehicles
    in
    { model | vehicles = vehiclesList } ! []


updateHull : Model -> Vehicle -> String -> ( Model, Cmd Msg )
updateHull model v strCurrent =
    let
        pre =
            List.take v.id model.vehicles

        nhull =
            v.hull

        current =
            String.toInt strCurrent |> Result.toMaybe |> Maybe.withDefault 0

        nv =
            { v | hull = { nhull | current = current } }

        post =
            List.drop (v.id + 1) model.vehicles

        newView = case model.view of
            Details v ->
                Details nv

            _ ->
                model.view
    in
    { model | view = newView, vehicles = pre ++ nv :: post } ! []


updateCrew : Model -> Vehicle -> String -> ( Model, Cmd Msg )
updateCrew model v strCurrent =
    let
        pre =
            List.take v.id model.vehicles

        current =
            String.toInt strCurrent |> Result.toMaybe |> Maybe.withDefault 0

        nv =
            { v | crew = current }

        post =
            List.drop (v.id + 1) model.vehicles
    in
    { model | vehicles = pre ++ nv :: post } ! []


updateEquipment : Model -> Vehicle -> String -> ( Model, Cmd Msg )
updateEquipment model v strCurrent =
    let
        pre =
            List.take v.id model.vehicles

        current =
            String.toInt strCurrent |> Result.toMaybe |> Maybe.withDefault 0

        nv =
            { v | equipment = current }

        post =
            List.drop (v.id + 1) model.vehicles
    in
    { model | vehicles = pre ++ nv :: post } ! []


updateNotes : Model -> Bool -> Vehicle -> String -> ( Model, Cmd Msg )
updateNotes model isPreview v notes =
    case isPreview of
        True ->
            { model | tmpVehicle = Just { v | notes = notes } } ! []

        False ->
            let
                vehiclesNew =
                    joinAround v.id { v | notes = notes } model.vehicles
            in
            { model | vehicles = vehiclesNew } ! []


deleteVehicle : Model -> Vehicle -> ( Model, Cmd Msg)
deleteVehicle model v =
    let
        newvehicles =
            deleteFromList v.id model.vehicles |> correctIds
    in
    { model | view = Overview, vehicles = newvehicles } ! []


deleteWeapon : Model -> Vehicle -> Weapon -> ( Model, Cmd Msg)
deleteWeapon model v w =
    let
        weaponsNew =
            deleteFromList w.id v.weapons |> correctIds

        vehicleUpdated =
            { v | weapons = weaponsNew }

        vehiclesNew =
            joinAround v.id vehicleUpdated model.vehicles
    in
    { model | view = Details vehicleUpdated, vehicles = vehiclesNew } ! []


deleteUpgrade : Model -> Vehicle -> Upgrade -> ( Model, Cmd Msg )
deleteUpgrade model v u=
    let
        upgradesNew =
            deleteFromList u.id v.upgrades |> correctIds

        vehicleUpdated =
            { v | upgrades = upgradesNew }

        vehiclesNew =
            joinAround v.id vehicleUpdated model.vehicles
    in
    { model | view = Details vehicleUpdated, vehicles = vehiclesNew  } ! []


deleteFromList : Int -> List a -> List a
deleteFromList index list =
    (List.take index list) ++ (List.drop (index + 1) list)


correctIds : List { a | id : Int } -> List { a | id : Int }
correctIds xs =
    List.indexedMap (\i x -> { x | id = i } ) xs


joinAround : Int -> a -> List a -> List a
joinAround i item xs =
    (List.take i xs) ++ item :: (List.drop (i + 1) xs)
