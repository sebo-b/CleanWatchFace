return {
    node_name: '',
    manifest: {
        timers: ['backlight','show_dial']
    },
    persist: {},
    config: {},

    whiteFace: false,
    backlight: false,

    log: function (object) {
        req_data(this.node_name, '"type": "log", "marker":"bebo","data":' + JSON.stringify(object), 999999, true);
    },

    sendEvent: function(response,event) {
        if (response.i == undefined)
            response.i = [];
        response.i.push(event);
    },

    init: function () {

    },

    handler: function (event, response) {

        //this.log(event);


        switch (event.type) {

            case 'ui_boot_up_done':
                response.action = {
                    type: 'go_visible',
                    class: 'home',
                };
                break;


            case 'system_state_update':

                if (event.de === true && // this app
                    event.le === 'visible') { // new state (ze: old state)
                        var hands = enable_time_telling();
                        response.move = {
                            h: hands.hour_pos,
                            m: hands.minute_pos,
                            is_relative: false
                        };
                        this.draw_watchface(response,true);
                }
                break;

            case 'time_telling_update':
                var hands = enable_time_telling();
                response.move = {
                    h: hands.hour_pos,
                    m: hands.minute_pos,
                    is_relative: false
                };
                break;

//            case 'middle_hold':
//                response.action = {
//                    type: 'go_home',
//                    Se: true    // kill app
//                };
//                break;

            case 'top_hold':
                this.whiteFace = !this.whiteFace;
                if (!this.backlight)
                    this.draw_watchface(response,true);
                break;

            case 'top_short_press_release':
                this.sendEvent(response,{ type: 'double_tap', class: 'user' });
                break;

            case 'bottom_short_press_release':
                disable_time_telling();
                this.draw_watchface(response,true);
                response.move = {
                    h: 180,
                    m: 180,
                    is_relative: false
                };
                start_timer(this.node_name, 'show_dial', 4000);
                break;

            case 'common_update':
                if (event.date === true)
                    this.draw_watchface(response);
                break;

            case 'double_tap':
                this.backlight = true;
                this.draw_watchface(response,true);
                start_timer(this.node_name, 'backlight', 4000);
                break;

            case 'timer_expired':
                if (is_this_timer_expired(event, this.node_name, 'backlight')) {
                    this.backlight = false;
                    this.draw_watchface(response,true);
                }
                else if (is_this_timer_expired(event, this.node_name, 'show_dial')) {
                    var hands = enable_time_telling();
                    response.move = {
                        h: hands.hour_pos,
                        m: hands.minute_pos,
                        is_relative: false
                    };
                }
                break;

            case 'node_config_update':
                if(event.node_name != this.node_name)
                    break;

                config_update(event, response);
                break;
        }



    },

    config_update: function (event, response) {


        // launch app from Gadgetbridge
        if(this.config.start_app != null){
            response.action = {
                type: 'open_app',
                node_name: this.config.start_app,
                class: 'watch_app',
            }
            delete this.config.start_app;
        }

    },

    draw_watchface: function (response, fullUpdate) { // function 2

        response.draw = {
            update_type: fullUpdate? 'gu4': 'du4'
        };

        var day = get_common().date;

        var layout_info = {
            json_file: 'watchface_layout',
            singleDateVis: (day < 10),
            doubleDateVis: (day >= 10),
            ltDigitDateImg: "num"+(day % 10),
            bgDigitDateImg: "num"+Math.floor(day / 10 ),
            whiteFace: this.whiteFace || this.backlight,
            indicesVis: this.backlight
        };

        layout_info['dayOfWeekImg'] = ['sun','mon','tue','wed','thu','fri','sat'][get_common().day];

        response.draw[this.node_name] = {
            layout_function: 'layout_parser_json',
            layout_info: layout_info
        }
    },

}
