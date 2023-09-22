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
// import { BlockVerifier } from "./hooks/block_verifier";
// Show copyright
// const setYear = () => {
//   const copyright = document.getElementById("copyright");
//   copyright.innerHTML = `LambdaClass &copy; ${new Date().getFullYear()}`;
// };
// setYear();

let Hooks = { };

// Hamburger menu
Hooks.Nav = {
  mounted() {
    const hamburger = document.getElementById("hamburger");
    const options = document.querySelector("#menu-options");
    const main = document.querySelector("main");
    hamburger.addEventListener("click", () => {
      options.classList.toggle("open");
      options.classList.toggle("opacity-0");
      options.classList.toggle("pointer-events-none");
      main.classList.toggle("hidden");
    });
  },
};

// Copy to clippboard
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

Hooks.Stats = {
  mounted() {
    new ApexCharts(document.querySelector("#transactions-chart"), transactions).render();
    new ApexCharts(document.querySelector("#fees"), fees).render();
    new ApexCharts(document.querySelector("#tvl"), tvl).render();
  },

  updated() {
    new ApexCharts(document.querySelector("#transactions-chart"), transactions).render();
    new ApexCharts(document.querySelector("#fees"), fees).render();
    new ApexCharts(document.querySelector("#tvl"), tvl).render();
  },
};

// Apex Chart for Stats
let randomizeArray = function (arg) {
  let array = arg.slice();
  let currentIndex = array.length,
    temporaryValue,
    randomIndex;

  while (0 !== currentIndex) {
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex -= 1;

    temporaryValue = array[currentIndex];
    array[currentIndex] = array[randomIndex];
    array[randomIndex] = temporaryValue;
  }

  return array;
};
// data for the sparklines that appear below header area
let sparklineData = [47, 45, 54, 38, 56, 24, 65, 31, 37, 39, 62, 51, 35, 41, 35, 27, 93, 53, 61, 27, 54, 43, 19, 46, 61, 27, 54, 43, 19, 46];

let transactions = {
  chart: {
    id: "transactions",
    type: "area",
    height: 160,
    background: "#1A1A24",
    sparkline: {
      enabled: true,
    },
  },
  tooltip: {
    theme: "dark",
  },
  stroke: {
    curve: "straight",
  },
  fill: {
    opacity: 1,
  },
  series: [
    {
      name: "Transactions",
      data: randomizeArray(sparklineData),
    },
  ],
  labels: [...Array(30).keys()].map((n) => `2018-09-0${n + 1}`),
  yaxis: {
    min: 0,
  },
  xaxis: {
    type: "datetime",
    categories: ["01 Jan", "02 Jan", "03 Jan", "04 Jan", "05 Jan", "06 Jan", "07 Jan", "08 Jan", "09 Jan", "10 Jan", "11 Jan", "12 Jan"],
  },
  colors: ["#b43cff"],
  title: {
    text: "424,652",
    offsetX: 20,
    style: {
      fontSize: "24px",
      cssClass: "apexcharts-yaxis-title",
      color: "white",
    },
  },
  subtitle: {
    text: "last month",
    offsetX: 20,
    style: {
      fontSize: "14px",
      cssClass: "apexcharts-yaxis-title",
      color: "#6B7280",
    },
  },
};
let fees = {
  chart: {
    id: "fees",
    type: "area",
    height: 160,
    background: "#1A1A24",
    sparkline: {
      enabled: true,
    },
  },
  tooltip: {
    theme: "dark",
  },
  stroke: {
    curve: "straight",
  },
  fill: {
    opacity: 1,
  },
  series: [
    {
      name: "fee",
      data: randomizeArray(sparklineData),
    },
  ],
  labels: [...Array(30).keys()].map((n) => `2018-09-0${n + 1}`),
  yaxis: {
    min: 0,
  },
  xaxis: {
    type: "datetime",
    categories: ["01 Jan", "02 Jan", "03 Jan", "04 Jan", "05 Jan", "06 Jan", "07 Jan", "08 Jan", "09 Jan", "10 Jan", "11 Jan", "12 Jan"],
  },
  colors: ["#b43cff"],
  title: {
    text: "33.83653 ETH",
    offsetX: 20,
    style: {
      fontSize: "24px",
      cssClass: "apexcharts-yaxis-title",
      color: "white",
    },
  },
  subtitle: {
    text: "last month",
    offsetX: 20,
    style: {
      fontSize: "14px",
      cssClass: "apexcharts-yaxis-title",
      color: "#6B7280",
    },
  },
};
let tvl = {
  chart: {
    id: "tvl",
    type: "area",
    height: 160,
    background: "#1A1A24",
    sparkline: {
      enabled: true,
    },
  },
  tooltip: {
    theme: "dark",
  },
  stroke: {
    curve: "straight",
  },
  fill: {
    opacity: 1,
  },
  series: [
    {
      name: "tvl",
      data: randomizeArray(sparklineData),
    },
  ],
  labels: [...Array(30).keys()].map((n) => `2018-09-0${n + 1}`),
  yaxis: {
    min: 0,
  },
  xaxis: {
    type: "datetime",
    categories: ["01 Jan", "02 Jan", "03 Jan", "04 Jan", "05 Jan", "06 Jan", "07 Jan", "08 Jan", "09 Jan", "10 Jan", "11 Jan", "12 Jan"],
  },
  colors: ["#b43cff"],
  title: {
    text: "$ 57,920,345",
    offsetX: 20,
    style: {
      fontSize: "24px",
      cssClass: "apexcharts-yaxis-title",
      color: "white",
    },
  },
  subtitle: {
    text: "last month",
    offsetX: 20,
    style: {
      fontSize: "14px",
      cssClass: "apexcharts-yaxis-title",
      color: "#6B7280",
    },
  },
};

// Tippy.js for Tooltip
tippy("#tps", {
  content: "The average transactions per second calculated from the last block",
});

//
Hooks.Network = {
  mounted() {
    const btn = document.querySelector("#nav-dropdown");
    const options = document.querySelector("nav #options");
    const listItems = document.querySelectorAll("nav .option");
    btn.addEventListener("click", () => {
      options.classList.toggle("hidden");
    });
    listItems.forEach((item) => {
      item.addEventListener("click", () => {
        options.classList.add("hidden");
      });
    });
  },
};
Hooks.Dropdown = {
  mounted() {
    const btn = document.querySelector("main .dropdown");
    const options = document.querySelector("main .options");
    const listItems = options.querySelectorAll("main .option");
    btn.addEventListener("click", () => {
      options.classList.toggle("hidden");
    });
    listItems.forEach((item) => {
      item.addEventListener("click", () => {
        options.classList.add("hidden");
      });
    });
  },
};

Hooks.SearchHook = {
  mounted() {
    const input = document.querySelector("#searchHook");
    const searchDropdown = document.querySelector("#dropdownInformation");
    input.addEventListener("click", () => { 
    })
    searchDropdown.classList.remove("hidden");
  },
  updated() {
    const input = document.querySelector("#searchHook");
    const searchDropdown = document.querySelector("#dropdownInformation");
    input.addEventListener("click", () => { 
      console.log(input);
    })
  }
};


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks });
// Show progress bar on live navigation and form submits. Only displays if still
// loading after 300 msec
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})

let topBarScheduled = undefined;
window.addEventListener("phx:page-loading-start", () => {
  if(!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 300);
  };
});
window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});


// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
