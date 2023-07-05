// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

// Show copyright
const setYear = () => {
  const copyright = document.getElementById("copyright");
  copyright.innerHTML = `LambdaClass &copy; ${new Date().getFullYear()}`;
};
setYear();

// Hamburger menu
const hamburgerMenu = () => {
  const hamburger = document.getElementById("hamburger");
  const options = document.querySelector("#menu-options");
  hamburger.addEventListener("click", () => {
    options.classList.toggle("open");
    options.classList.toggle("opacity-0");
    options.classList.toggle("pointer-events-none");
    document.body.classList.toggle("overflow-hidden");
  });
};
hamburgerMenu();

// Copy to clippboard

let Hooks = {};
Hooks.Copy = {
  mounted() {
    const copySections = document.querySelectorAll(".copy-container");
    copySections.forEach((section) => {
      const copyText = section.querySelector(".copy-text");
      const copyButton = section.querySelector(".copy-btn");
      const copyCheck = section.querySelector(".copy-check");
      copyButton.addEventListener("click", () => {
        if (copyText.dataset.text != null || copyCheck.dataset.text != undefined) {
          navigator.clipboard.writeText(copyText.dataset.text);
        } else {
          navigator.clipboard.writeText(copyText.innerHTML);
        }
        copyButton.style.opacity = "0";
        copyCheck.style.opacity = "100";
        setTimeout(() => {
          copyButton.style.opacity = "100";
          copyCheck.style.opacity = "0";
        }, 1000);
      });
    });
  },
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks });

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
