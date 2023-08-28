(defonce vim-hearth-async-results (atom nil))

(defmethod cljs.test/report [:vim-hearth :end-run-tests] [m]
  (swap! vim-hearth-async-results assoc :end m))

(defmethod cljs.test/report [:vim-hearth :fail] [m]
  (let [env (cljs.test/get-current-env)]
    (swap! vim-hearth-async-results update :fails
           (fnil conj [])
           (assoc m
                  :vars (seq (:testing-vars env))
                  :contexts (when (seq (:testing-contexts env))
                              (cljs.test/testing-contexts-str))))))

(defmethod cljs.test/report [:vim-hearth :error] [m]
  (cljs.test/report (assoc m :type :fail)))

(defmethod cljs.test/report [:cljs.test/default :hearth-report] [_]
  (let [state @vim-hearth-async-results]
    (when (:end state)
      (clojure.string/trim
        (with-out-str
          (doseq [{:keys [file line type] test :name :as m} (:fails state)]
            (let [last-var-meta (meta (last (:vars m)))]
              (println (clojure.string/join
                         "\t" [(or (when-not (= "@" file)
                                     file)
                                   (:file last-var-meta)
                                   "NO_SOURCE_FILE")
                               (or (when-not (NaN? line)
                                     line)
                                   (:line last-var-meta))
                               (name type)
                               (or test
                                   (:name last-var-meta))]))
              (when-let [contexts (:contexts m)] (println contexts))
              (when-let [msg (:message m)] (println msg))
              (println "expected:" (pr-str (:expected m)))
              (println "  actual:" #_(pr-str (:actual m)))
              (cljs.pprint/pprint (:actual m))))

          (let [stdout (:stdout state)]
            (when-not (empty? stdout)
              (println "\nStandard Output:")
              (println stdout))))))))

(defn report-test-output [output]
  (swap! vim-hearth-async-results assoc :stdout output))

(reset! vim-hearth-async-results nil)
