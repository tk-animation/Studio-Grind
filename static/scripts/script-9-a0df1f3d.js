
      const goatcounterScriptPre = document.createElement('script');
      goatcounterScriptPre.textContent = `
        window.goatcounter = { no_onload: true };
      `;
      document.head.appendChild(goatcounterScriptPre);

      const endpoint = "https://tkanimation.goatcounter.com/count";
      const counterBase = "https://tkanimation.goatcounter.com/counter/";
      const updateGoatCounterViews = () => {
        const targets = document.querySelectorAll('[data-goatcounter-views]');
        if (targets.length === 0) return;

        fetch(counterBase + encodeURIComponent(location.pathname) + '.json')
          .then((response) => {
            if (!response.ok) throw new Error('GoatCounter visitor counter is unavailable');
            return response.json();
          })
          .then((data) => {
            const count = data.count ?? data.count_unique;
            if (count === undefined) return;
            targets.forEach((target) => {
              target.textContent = String(count);
            });
          })
          .catch(() => {});
      };
      const goatcounterScript = document.createElement('script');
      goatcounterScript.src = "https://gc.zgo.at/count.js";
      goatcounterScript.defer = true;
      goatcounterScript.setAttribute('data-goatcounter', endpoint);
      goatcounterScript.onload = () => {
        window.goatcounter.endpoint = endpoint;
        goatcounter.count({ path: location.pathname });
        updateGoatCounterViews();
        document.addEventListener('nav', () => {
          goatcounter.count({ path: location.pathname });
          updateGoatCounterViews();
        });
      };

      document.head.appendChild(goatcounterScript);
    