// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "./application"

// Manually import controllers
import HelloController from "./hello_controller"
import FormSubmitController from "./form_submit_controller"
import AutosubmitController from "./autosubmit_controller"

application.register("hello", HelloController)
application.register("form-submit", FormSubmitController)
application.register("autosubmit", AutosubmitController)
