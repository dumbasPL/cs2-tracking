const SteamUser = require("steam-user");
const child_process = require('child_process');

const client = new SteamUser({
  picsCacheAll: true,
  enablePicsCache: true,
  changelistUpdateInterval: 10000,
});

client.on('appUpdate', onAppUpdate);

client.on('error', (err) => {
  console.log(err);
});

client.on('loggedOn', () => {
  console.log('Logged into Steam');
});

client.logOn({
  accountName: process.env.STEAM_USERNAME,
  password: process.env.STEAM_PASSWORD,
});

function onAppUpdate(appId, data) {
  const {appinfo} = data;
  if (!appinfo || appinfo.appid != '730' || !appinfo.depots) {
    return;
  }

  console.log(`App ${appId} updated: ${JSON.stringify(data)}`);

  const depot = appinfo.depots['2347771'];
  if (!depot || !depot.manifests || !depot.manifests.public) {
    return;
  }

  const manifest = depot.manifests.public;

  child_process.spawn('/bin/bash', ['/run.sh', manifest.gid], {stdio: 'inherit'});
}

// onAppUpdate(730, {
//   appinfo: {
//     appid: '730',
//     depots: {
//       '2347771': {
//         manifests: {
//           public: {
//             gid: '123456',
//           },
//         },
//       },
//     },
//   },
// });