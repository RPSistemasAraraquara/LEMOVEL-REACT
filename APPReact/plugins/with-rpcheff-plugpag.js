const fs = require('fs');
const path = require('path');
const {
  AndroidConfig,
  createRunOncePlugin,
  withAndroidManifest,
  withAppBuildGradle,
  withDangerousMod
} = require('@expo/config-plugins');

const PLUGIN_NAME = 'with-rpcheff-plugpag';
const PLUGIN_VERSION = '1.1.0';

const PAGBANK_PACKAGES = [
  'br.com.uol.pagseguro.plugpagservice',
  'br.com.uol.pagseguro.terminallibservice',
  'br.com.uol.pagseguro.plugpag.libterminal.appservice',
  'com.ads.lio.uriappclient'
];

const QUERY_SCHEMES = [
  'payment-app',
  'cancel-app',
  'printer-app',
  'reprinter-app',
  'lio',
  'orderpay',
  'ordercancel',
  'print',
  'stone-rpmobile',
  'stone-rpmobile-cancel'
];

const JAR_FILES = [
  'wrapper-1.33.0.jar',
  'rxjava-2.1.16.jar',
  'rxandroid-2.0.2.jar',
  'reactive-streams-1.0.2.jar',
  'mvp-common-2.0.1.jar',
  'mvp-2.0.1.jar',
  'fastutil-8.4.0.jar',
  'r.jar'
];

function ensureArray(value) {
  if (!value) return [];
  return Array.isArray(value) ? value : [value];
}

function getManifestRoot(manifest) {
  return manifest.manifest || manifest;
}

function addUsesPermission(manifest, permission) {
  const root = getManifestRoot(manifest);
  root['uses-permission'] = ensureArray(root['uses-permission']);
  const exists = root['uses-permission'].some(
    (item) => item && item.$ && item.$['android:name'] === permission
  );
  if (!exists) {
    root['uses-permission'].push({ $: { 'android:name': permission } });
  }
}

function addUsesFeature(manifest, featureName, required) {
  const root = getManifestRoot(manifest);
  root['uses-feature'] = ensureArray(root['uses-feature']);
  const exists = root['uses-feature'].some(
    (item) => item && item.$ && item.$['android:glEsVersion'] === featureName
  );
  if (!exists) {
    root['uses-feature'].push({
      $: {
        'android:glEsVersion': featureName,
        'android:required': required ? 'true' : 'false'
      }
    });
  }
}

function addQueryPackagesAndIntents(manifest) {
  const root = getManifestRoot(manifest);
  root.queries = ensureArray(root.queries);
  if (root.queries.length === 0) {
    root.queries.push({});
  }

  const query = root.queries[0];
  query.package = ensureArray(query.package);
  query.intent = ensureArray(query.intent);

  const existingPackages = new Set(
    query.package
      .map((item) => item && item.$ && item.$['android:name'])
      .filter(Boolean)
  );

  PAGBANK_PACKAGES.forEach((pkg) => {
    if (!existingPackages.has(pkg)) {
      query.package.push({ $: { 'android:name': pkg } });
    }
  });

  const existingSchemes = new Set(
    query.intent
      .flatMap((intent) => ensureArray(intent.data))
      .map((data) => data && data.$ && data.$['android:scheme'])
      .filter(Boolean)
  );

  QUERY_SCHEMES.forEach((scheme) => {
    if (!existingSchemes.has(scheme)) {
      query.intent.push({
        action: [{ $: { 'android:name': 'android.intent.action.VIEW' } }],
        data: [{ $: { 'android:scheme': scheme } }]
      });
    }
  });
}

function addProviderAndMeta(manifest) {
  const app = AndroidConfig.Manifest.getMainApplicationOrThrow(manifest);

  app.$ = app.$ || {};
  app.$['android:allowBackup'] = 'false';
  app.$['android:hardwareAccelerated'] = 'true';
  app.$['android:requestLegacyExternalStorage'] = 'true';
  app.$['android:resizeableActivity'] = 'true';
  app.$['android:usesCleartextTraffic'] = 'true';

  app.provider = ensureArray(app.provider);
  const hasProvider = app.provider.some(
    (item) =>
      item &&
      item.$ &&
      item.$['android:name'] ===
        'br.com.uol.pagseguro.plugpag.terminallib.wrapper.provider.TerminalServiceFileProvider'
  );

  if (!hasProvider) {
    app.provider.push({
      $: {
        'android:name':
          'br.com.uol.pagseguro.plugpag.terminallib.wrapper.provider.TerminalServiceFileProvider',
        'android:authorities': '${applicationId}.wrapper.ts.provider',
        'android:exported': 'false',
        'android:grantUriPermissions': 'true'
      },
      'meta-data': [
        {
          $: {
            'android:name': 'android.support.FILE_PROVIDER_PATHS',
            'android:resource': '@xml/provider_paths'
          }
        }
      ]
    });
  }

  app['meta-data'] = ensureArray(app['meta-data']);
  const hasCieloMeta = app['meta-data'].some(
    (item) => item && item.$ && item.$['android:name'] === 'cs_integration_type'
  );
  if (!hasCieloMeta) {
    app['meta-data'].push({
      $: {
        'android:name': 'cs_integration_type',
        'android:value': 'uri'
      }
    });
  }
}

function createViewIntentFilter(scheme, host, browsable) {
  const categories = [{ $: { 'android:name': 'android.intent.category.DEFAULT' } }];
  if (browsable) {
    categories.push({ $: { 'android:name': 'android.intent.category.BROWSABLE' } });
  }

  const data = host
    ? [{ $: { 'android:scheme': scheme, 'android:host': host } }]
    : [{ $: { 'android:scheme': scheme } }];

  return {
    action: [{ $: { 'android:name': 'android.intent.action.VIEW' } }],
    category: categories,
    data
  };
}

function hasIntentFilter(activity, scheme, host, actionName) {
  const filters = ensureArray(activity['intent-filter']);
  return filters.some((intent) => {
    const actions = ensureArray(intent.action)
      .map((item) => item && item.$ && item.$['android:name'])
      .filter(Boolean);
    if (!actions.includes(actionName)) return false;

    if (!scheme) return true;
    const data = ensureArray(intent.data);
    return data.some((item) => {
      const intentScheme = item && item.$ && item.$['android:scheme'];
      const intentHost = item && item.$ && item.$['android:host'];
      if (intentScheme !== scheme) return false;
      if (!host) return true;
      return intentHost === host;
    });
  });
}

function addMainActivityIntentFilters(manifest) {
  const activity = AndroidConfig.Manifest.getMainActivityOrThrow(manifest);
  activity['intent-filter'] = ensureArray(activity['intent-filter']);

  const viewFilters = [
    createViewIntentFilter('stone-rpmobile', 'pay-response', true),
    createViewIntentFilter('stone-rpmobile-cancel', 'cancel', true),
    createViewIntentFilter('stone-rpmobile', 'print', true),
    createViewIntentFilter('stone-rpmobile', 'reprint', true),
    createViewIntentFilter('orderpay', 'response', false),
    createViewIntentFilter('ordercancel', 'response', false),
    createViewIntentFilter('print', 'response', false)
  ];

  viewFilters.forEach((filter) => {
    const data = ensureArray(filter.data)[0];
    const scheme = data && data.$ && data.$['android:scheme'];
    const host = data && data.$ && data.$['android:host'];
    if (!hasIntentFilter(activity, scheme, host, 'android.intent.action.VIEW')) {
      activity['intent-filter'].push(filter);
    }
  });

  if (!hasIntentFilter(activity, null, null, 'br.com.uol.pagseguro.PAYMENT')) {
    activity['intent-filter'].push({
      action: [{ $: { 'android:name': 'br.com.uol.pagseguro.PAYMENT' } }],
      category: [{ $: { 'android:name': 'android.intent.category.DEFAULT' } }]
    });
  }
}

function patchBuildGradle(contents) {
  let next = contents;

  const libsFileTree = 'implementation fileTree(dir: "libs", include: ["*.jar", "*.aar"])';
  if (!next.includes(libsFileTree)) {
    if (next.includes('implementation fileTree(dir: "libs", include: ["*.jar"])')) {
      next = next.replace(
        'implementation fileTree(dir: "libs", include: ["*.jar"])',
        libsFileTree
      );
    } else {
      next = next.replace(/dependencies\s*\{/m, (match) => `${match}\n    ${libsFileTree}`);
    }
  }

  if (!next.includes('META-INF/*.kotlin_module')) {
    const block = `\n    packagingOptions {\n        resources {\n            excludes += [\"META-INF/*.kotlin_module\", \"META-INF/DEPENDENCIES\", \"META-INF/LICENSE*\", \"META-INF/NOTICE*\"]\n        }\n    }\n`;
    if (next.includes('android {') && next.includes('defaultConfig {')) {
      next = next.replace('defaultConfig {', `${block}    defaultConfig {`);
    }
  }

  return next;
}

function copyIfExists(source, target) {
  if (!fs.existsSync(source)) return false;
  fs.copyFileSync(source, target);
  return true;
}

function writeFileIfChanged(target, contents) {
  if (fs.existsSync(target)) {
    const current = fs.readFileSync(target, 'utf8');
    if (current === contents) return;
  }
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, contents, 'utf8');
}

function copyDirectoryRecursive(sourceDir, targetDir) {
  if (!fs.existsSync(sourceDir)) return;

  const entries = fs.readdirSync(sourceDir, { withFileTypes: true });
  entries.forEach((entry) => {
    const source = path.join(sourceDir, entry.name);
    const target = path.join(targetDir, entry.name);

    if (entry.isDirectory()) {
      copyDirectoryRecursive(source, target);
      return;
    }

    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.copyFileSync(source, target);
  });
}

function findMainApplicationFile(androidRoot) {
  const javaRoot = path.join(androidRoot, 'app', 'src', 'main', 'java');
  if (!fs.existsSync(javaRoot)) return null;

  const stack = [javaRoot];
  while (stack.length > 0) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(full);
      } else if (
        entry.isFile() &&
        (entry.name === 'MainApplication.java' || entry.name === 'MainApplication.kt')
      ) {
        return full;
      }
    }
  }

  return null;
}

function patchMainApplication(contents, isKotlin) {
  let next = contents;
  const importLine = isKotlin
    ? 'import com.rpcheff.plugpag.RPCheffPlugPagPackage'
    : 'import com.rpcheff.plugpag.RPCheffPlugPagPackage;';

  if (!next.includes(importLine)) {
    if (isKotlin) {
      next = next.replace(
        /import com\.facebook\.react\.PackageList/m,
        `import com.facebook.react.PackageList\n${importLine}`
      );
    } else {
      next = next.replace(
        /import com\.facebook\.react\.PackageList;/m,
        `import com.facebook.react.PackageList;\n${importLine}`
      );
    }
  }

  if (
    next.includes('packages.add(RPCheffPlugPagPackage())') ||
    next.includes('packages.add(new RPCheffPlugPagPackage())')
  ) {
    return next;
  }

  if (isKotlin) {
    if (/val packages = PackageList\(this\)\.packages/m.test(next)) {
      next = next.replace(
        /val packages = PackageList\(this\)\.packages/m,
        'val packages = PackageList(this).packages\n      packages.add(RPCheffPlugPagPackage())'
      );
    } else {
      next = next.replace(
        /return PackageList\(this\)\.packages/m,
        'val packages = PackageList(this).packages\n      packages.add(RPCheffPlugPagPackage())\n      return packages'
      );
    }
  } else {
    next = next.replace(
      /List<ReactPackage>\s+packages\s*=\s*new PackageList\(this\)\.getPackages\(\);/m,
      'List<ReactPackage> packages = new PackageList(this).getPackages();\n      packages.add(new RPCheffPlugPagPackage());'
    );
  }

  return next;
}

function withRPCheffPlugPag(config) {
  config = withAndroidManifest(config, (mod) => {
    const manifest = mod.modResults;
    addUsesPermission(manifest, 'android.permission.ACCESS_COARSE_LOCATION');
    addUsesPermission(manifest, 'android.permission.ACCESS_FINE_LOCATION');
    addUsesPermission(manifest, 'android.permission.CAMERA');
    addUsesPermission(manifest, 'android.permission.INTERNET');
    addUsesPermission(manifest, 'android.permission.READ_PHONE_STATE');
    addUsesPermission(manifest, 'android.permission.READ_MEDIA_IMAGES');
    addUsesPermission(manifest, 'android.permission.READ_EXTERNAL_STORAGE');
    addUsesPermission(manifest, 'android.permission.WRITE_EXTERNAL_STORAGE');
    addUsesPermission(manifest, 'br.com.uol.pagseguro.permission.MANAGE_PAYMENTS');
    addUsesFeature(manifest, '0x00020000', true);
    addQueryPackagesAndIntents(manifest);
    addProviderAndMeta(manifest);
    addMainActivityIntentFilters(manifest);
    return mod;
  });

  config = withAppBuildGradle(config, (mod) => {
    mod.modResults.contents = patchBuildGradle(mod.modResults.contents);
    return mod;
  });

  config = withDangerousMod(config, [
    'android',
    async (mod) => {
      const projectRoot = mod.modRequest.projectRoot;
      const androidRoot = mod.modRequest.platformProjectRoot;

      const sourceLibRoot = path.join(projectRoot, '..', 'Fontes', 'libs');
      const targetLibRoot = path.join(androidRoot, 'app', 'libs');
      fs.mkdirSync(targetLibRoot, { recursive: true });

      const missing = [];
      JAR_FILES.forEach((fileName) => {
        const source = path.join(sourceLibRoot, fileName);
        const target = path.join(targetLibRoot, fileName);
        const copied = copyIfExists(source, target);
        if (!copied) {
          missing.push(fileName);
        }
      });

      if (missing.length > 0) {
        throw new Error(
          `[with-rpcheff-plugpag] Arquivos PagBank nao encontrados em ${sourceLibRoot}: ${missing.join(', ')}`
        );
      }

      const templateRoot = path.join(projectRoot, 'plugins', 'android-src');
      const javaDir = path.join(androidRoot, 'app', 'src', 'main', 'java', 'com', 'rpcheff', 'plugpag');
      fs.mkdirSync(javaDir, { recursive: true });

      const templateFiles = [
        'RPCheffPlugPagModule.java',
        'RPCheffStoneModule.java',
        'RPCheffCieloModule.java',
        'RPCheffPlugPagPackage.java'
      ];

      templateFiles.forEach((fileName) => {
        const source = path.join(templateRoot, fileName);
        if (!fs.existsSync(source)) {
          throw new Error(`[with-rpcheff-plugpag] Template Android nao encontrado: ${source}`);
        }
        const target = path.join(javaDir, fileName);
        const content = fs.readFileSync(source, 'utf8');
        writeFileIfChanged(target, content);
      });

      const providerPathsSource = path.join(templateRoot, 'provider_paths.xml');
      if (!fs.existsSync(providerPathsSource)) {
        throw new Error(`[with-rpcheff-plugpag] Template Android nao encontrado: ${providerPathsSource}`);
      }
      const providerPathsTarget = path.join(
        androidRoot,
        'app',
        'src',
        'main',
        'res',
        'xml',
        'provider_paths.xml'
      );
      writeFileIfChanged(providerPathsTarget, fs.readFileSync(providerPathsSource, 'utf8'));

      copyDirectoryRecursive(
        path.join(templateRoot, 'aidl'),
        path.join(androidRoot, 'app', 'src', 'main', 'aidl')
      );
      copyDirectoryRecursive(
        path.join(templateRoot, 'com'),
        path.join(androidRoot, 'app', 'src', 'main', 'java', 'com')
      );

      const mainApplicationPath = findMainApplicationFile(androidRoot);
      if (mainApplicationPath) {
        const current = fs.readFileSync(mainApplicationPath, 'utf8');
        const isKotlin = mainApplicationPath.endsWith('.kt');
        const patched = patchMainApplication(current, isKotlin);
        if (patched !== current) {
          fs.writeFileSync(mainApplicationPath, patched, 'utf8');
        }
      }

      return mod;
    }
  ]);

  return config;
}

module.exports = createRunOncePlugin(withRPCheffPlugPag, PLUGIN_NAME, PLUGIN_VERSION);
