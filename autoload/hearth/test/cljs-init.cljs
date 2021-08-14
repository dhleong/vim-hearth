(defonce vim-hearth-async-results (atom nil))

(defmethod cljs.test/report [:vim-hearth :end-run-tests] [m]
  (swap! vim-hearth-async-results assoc :end m))

(defmethod cljs.test/report [:vim-hearth :fail] [m]
  (let [env (cljs.test/get-current-env)]
    (swap! vim-hearth-async-results update :fails
           (fnil conj [])
           (assoc m :contexts
                  (when (seq (:testing-contexts env))
                    (cljs.test/testing-contexts-str))))))

(defmethod cljs.test/report [:vim-hearth :error] [m]
  (cljs.test/report (assoc m :type :fail)))

(defmethod cljs.test/report [:cljs.test/default :hearth-report] [_]
  (let [state @vim-hearth-async-results]
    (when (:end state)
      (clojure.string/trim
        (with-out-str
          (doseq [{:keys [file line type] test :name :as m} (:fails state)]
            (println (clojure.string/join
                       "\t" [file line (name type) test]))
            (when-let [contexts (:contexts m)] (println contexts))
            (when-let [msg (:message m)] (println msg))
            (println "expected:" (pr-str (:expected m)))
            (println "  actual:" #_(pr-str (:actual m)))
            (cljs.pprint/pprint (:actual m))))))))

(reset! vim-hearth-async-results nil)
