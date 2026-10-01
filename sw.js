/* SCL service worker: always loads the newest page, clears old caches, keeps notification taps working. */
self.addEventListener('install',function(){self.skipWaiting()});
self.addEventListener('activate',function(e){e.waitUntil(caches.keys().then(function(ks){return Promise.all(ks.map(function(k){return caches.delete(k)}))}).then(function(){return self.clients.claim()}))});
self.addEventListener('notificationclick',function(e){e.notification.close();e.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(function(cs){for(var i=0;i<cs.length;i++){if('focus' in cs[i])return cs[i].focus()}if(self.clients.openWindow)return self.clients.openWindow('./')}))});
self.addEventListener("install",()=>self.skipWaiting()); self.addEventListener("activate",e=>e.waitUntil(self.clients.claim()));
