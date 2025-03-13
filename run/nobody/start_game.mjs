import http from 'http';
import assert from 'assert';

async function send_request(host, method, data = {}, session_cookie = '') {
  let path = '/index.html?lang=en';
  const origin = 'http://' + host;
  const target = origin + path;
  const headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Accept-Language': 'de,en-US;q=0.7,en;q=0.3',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Fetch-User': '?1',
    Priority: 'u=0, i',
    'Upgrade-Insecure-Requests': 1,
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:134.0) Gecko/20100101 Firefox/134.0',
    Referer: target,
    Origin: origin,
  };
  if (session_cookie !== '') {
    headers['Cookie'] = session_cookie;
  }
  let body = '';
  for (const key of Object.keys(data)) {
    if (body.length > 0) {
      body += '&';
    }
    if (data[key].startsWith('+%2B+')) {
      data[key] = encodeURIComponent(data[key].replace('+%2B+', '')).replace(
        /%20/g,
        '+'
      );
    } else {
      data[key] = encodeURIComponent(data[key]);
    }
    body += key + '=' + data[key];
  }
  if (method === 'POST') {
    headers['Content-Length'] = body.length;
  }
  if (method === 'GET' && Object.keys(data).length > 0) {
    path += '&' + body;
  }
  const agent = new http.Agent({keepAlive: false});
  const options = {
    method,
    headers,
    agent,
  };
  console.log('Request:', method, target);
  console.log('Headers:', JSON.stringify(options.headers, null, 2));
  if (method === 'POST') {
    console.log('Body:', body);
  }
  return new Promise((resolve, reject) => {
    const req = http.request(target, options, (res) => {
      assert(typeof res.statusCode === 'number');
      console.log('Response:', res.statusCode);
      assert(res.statusCode >= 200 && res.statusCode < 400);
      res['text'] = async () => {
        return new Promise((resolve_text) => {
          let data = '';
          res.on('data', (chunk) => {
            data += chunk;
          });
          res.on('end', () => {
            resolve_text(data);
          });
        });
      };
      resolve(res);
    });
    req.on('error', (err) => {
      reject(err);
    });
    if (method === 'POST') {
      req.write(body);
    }
    req.end();
  });
}

async function login(host, username, password) {
  const res = await send_request(host, 'GET');
  const cookies = res.headers['set-cookie'];
  assert(Array.isArray(cookies));
  let session_cookie_result = null;

  for (const cookie of cookies) {
    session_cookie_result = /(SessionID=[^;]+)/i.exec(cookie);
    if (session_cookie_result !== null) break;
  }
  assert(session_cookie_result !== null);

  const request = {
    username: username,
    password: password,
    login: 'Login',
  };
  await send_request(host, 'POST', request, session_cookie_result[1]);
  return session_cookie_result[1];
}

const expected_start_params = [
  'game_name',
  'admin_password',
  'game_password',
  'savegame',
  'server_port',
  'max_player',
  'mp_language',
  'auto_save_interval',
  'stats_interval',
  'pause_game_if_empty',
];

function get_regex(text, regex) {
  const reg = new RegExp(regex, 'igsu');
  const results = {};
  let match;
  while ((match = reg.exec(text)) !== null) {
    if (!expected_start_params.includes(match[1])) continue;
    results[match[1]] = match[2];
  }
  return results;
}

let main_interval = null;

async function main() {
  const host = process.env.WEBSERVER_LISTENING_ON + ':7999';

  console.log('Starting game');
  console.log('Host:', host);

  const session_cookie = await login(
    host,
    process.env.WEB_USERNAME,
    process.env.WEB_PASSWORD
  );

  console.log('Logged in');
  console.log('Session cookie:', session_cookie);

  const res = await send_request(host, 'GET', {}, session_cookie);

  const html = await res.text();

  const unsorted_params = {
    ...get_regex(html, '<input type="[^"]*" name="([^"]*)" value="([^"]*)"'),
    ...get_regex(
      html,
      '<select name\\s*=\\s*"([^"]*)".*?<option value="([^"]*)" selected="selected"'
    ),
  };

  const params = {};
  for (const key of expected_start_params) {
    assert(typeof unsorted_params[key] !== 'undefined', 'Missing key: ' + key);
    params[key] = unsorted_params[key];
  }
  params['game_name'] = '+%2B+' + params['game_name'];
  params['start_server'] = 'Start';

  console.log('Starting server');
  console.log(JSON.stringify(params, null, 2));

  await send_request(host, 'POST', params, session_cookie);

  console.log('Server started');
  clearInterval(main_interval);
}

main_interval = setInterval(() => main().catch(console.error), 30000);
main().catch(console.error);
