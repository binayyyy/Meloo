export default function BlockedPage() {
  return (
    <main className="auth-shell">
      <div className="auth-stage">
        <section className="auth-card blocked-card">
          <p className="eyebrow">Restricted surface</p>
          <h1>Desktop required</h1>
          <p>
            The admin console is limited to desktop access for internal review
            and operations workflows.
          </p>
        </section>
      </div>
    </main>
  );
}
