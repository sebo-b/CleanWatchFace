
return {
    node_name: '',
    config: {},

    init: function() {},

    handler: function(event, response) {

        switch (event.type) {

            case 'ui_boot_up_done':
                response.action = {
                    type: 'go_visible',
                    class: 'home',
                };
                break;

            case  'system_state_update':
                response.draw = {
                    node_name: this.node_name,
                    package_name: this.package_name,
                    background: 'background',
    //                layout_function: 'layout_parser_json',
    //                layout_info: {
    //                    json_file: 'watchface_layout'
    //                },
                    update_type: 'gc4'
                };
    //                array: [],
    //                skip_invert: true,
    //                update_type: /*this.full_refresh_needed ?*/ 'gc4'/* : 'du4'*/,

                /* NO BREAK*/

            case 'time_telling_update':
                var hands = enable_time_telling();
                response.move = {
                    h: hands.hour_pos,
                    m: hands.minute_pos,
                    is_relative: false,
                };
                break;
        }

    },
};

