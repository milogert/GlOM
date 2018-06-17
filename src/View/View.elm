module View.View exposing (view)

import Html exposing (Html, button, div, h1, h2, h3, h4, h5, h6, hr, img, input, label, li, node, option, p, select, small, span, text, textarea, ul, form, a)
import Html.Attributes exposing (checked, class, classList, disabled, for, href, id, max, min, placeholder, rel, src, type_, value, readonly, style)
import Html.Events exposing (onClick, onInput)
import Model.Model exposing (..)
import View.Details
import View.ImportExport
import View.NewUpgrade
import View.NewVehicle
import View.NewWeapon
import View.Overview
import View.Utils exposing (..)


view : Model -> Html Msg
view model =
    let
        viewToGoTo =
            case model.view of
                Details _ ->
                    ToOverview

                AddingVehicle ->
                    ToOverview

                AddingWeapon v ->
                    ToDetails v

                AddingUpgrade v ->
                    ToDetails v

                ImportExport ->
                    ToOverview

                Overview ->
                    ToOverview

        backButton =
            button
                [ -- classList [ ( "d-none", model.view == Overview ) ]
                  disabled <| model.view == Overview
                , class "btn btn-light btn-sm btn-block"
                , onClick viewToGoTo
                ]
                [ icon "arrow-left" ]

        currentPoints =
            totalPoints model

        maxPoints =
            model.pointsAllowed

        gearPhaseText =
            (toString model.gearPhase)
    in
        div [ class "container" ]
            [ View.Utils.rowPlus [ "mt-2" ]
                [ View.Utils.colPlus [ "auto" ] [ "my-auto" ] [ backButton ]
                , View.Utils.colPlus [ "md", "sm-12" ]
                    []
                    [ h2 [ style [ ( "margin-bottom", "0" ) ] ]
                        [ text <| viewToStr model.view
                        ]
                    ]
                , View.Utils.colPlus [ "auto" ]
                    [ "my-auto" ]
                    [ button
                        [ class "btn btn-sm btn-primary btn-block"
                        , value <| toString model.gearPhase
                        , onClick NextGearPhase
                        ]
                        [ icon "cogs", text gearPhaseText ]
                    ]
                , View.Utils.colPlus [ "lg-2", "md-3", "sm" ]
                    [ "my-auto" ]
                    [ div [ class "form-group form-row mb-0" ]
                        [ label
                            [ for "squadPoints"
                            , class "col-form-label"
                            ]
                            [ text <| (toString <| currentPoints) ++ " of" ]
                        , col ""
                            [ input
                                [ type_ "number"
                                , class "form-control form-control-sm my-1"
                                , classList
                                    [ ( "above-points", currentPoints > maxPoints )
                                    , ( "at-points", currentPoints == maxPoints )
                                    , ( "below-points", currentPoints < maxPoints )
                                    ]
                                , id "squadPoints"
                                , value <| toString maxPoints
                                , onInput UpdatePointsAllowed
                                ]
                                []
                            ]
                        ]
                    ]
                , View.Utils.colPlus
                    [ "auto" ]
                    [ "my-auto" ]
                    [ button
                        [ class "btn btn-sm btn-block btn-light", onClick ToExport ]
                        [ icon "download", text " / ", icon "upload" ]
                    ]
                ]
            , hr [] []
            , displayAlert model
            , render model
            ]


displayAlert : Model -> Html Msg
displayAlert model =
    case model.error of
        [] ->
            text ""

        _ ->
            div [] <|
                List.map
                    (\x ->
                        (row
                            [ div
                                [ class "col alert alert-danger" ]
                                [ text <| errorToStr x ]
                            ]
                        )
                    )
                    model.error


render : Model -> Html Msg
render model =
    case model.view of
        Overview ->
            View.Overview.view model

        Details v ->
            View.Details.view model v

        AddingVehicle ->
            View.NewVehicle.view model

        AddingWeapon v ->
            View.NewWeapon.view model v

        AddingUpgrade v ->
            View.NewUpgrade.view model v

        ImportExport ->
            View.ImportExport.view model
