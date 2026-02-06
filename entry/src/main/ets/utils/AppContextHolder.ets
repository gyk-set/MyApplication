import type common from '@ohos.app.ability.common';

let appContext: common.Context | undefined = undefined;

// Store ability context for modules that need to access system storage.
export function setAppContext(ctx: common.Context): void {
  appContext = ctx;
}

export function getAppContext(): common.Context {
  if (!appContext) {
    throw new Error('App context is not initialized yet.');
  }
  return appContext;
}

