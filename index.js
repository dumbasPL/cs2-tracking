const SteamUser = require("steam-user");
const child_process = require('child_process');

const APP_ID = 730;
const DEPOT_ID = 2347771;
let lastManifest = null;

const client = new SteamUser({
  picsCacheAll: true,
  enablePicsCache: true,
  changelistUpdateInterval: 10000,
});

client.on('appUpdate', onAppUpdate);

client.on('error', (err) => {
  console.error(err);
  process.exit(1);
});

client.on('loggedOn', async () => {
  try {
    console.log('Logged into Steam');
    const res = await client.getProductInfo([APP_ID], [], true);
    lastManifest = res.apps[APP_ID].appinfo.depots[`${DEPOT_ID}`].manifests.public.gid;
    console.log(`Last manifest: ${lastManifest}`);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})

client.logOn({
  accountName: process.env.STEAM_USERNAME,
  password: process.env.STEAM_PASSWORD,
});

function onAppUpdate(appId, data) {
  const {appinfo} = data;
  if (!appinfo || appinfo.appid != `${APP_ID}` || !appinfo.depots) {
    return;
  }

  console.log(`App ${appId} updated: ${JSON.stringify(data)}`);

  const depot = appinfo.depots[`${DEPOT_ID}`];
  if (!depot || !depot.manifests || !depot.manifests.public) {
    return;
  }

  const manifest = depot.manifests.public;

  if (!lastManifest) {
    console.warn('Last manifest is not set during update, defaulting to current manifest: ' + manifest.gid);
    lastManifest = manifest.gid;
    return;
  }

  if (lastManifest == manifest.gid) {
    console.log('Manifest has not changed');
    return;
  }

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