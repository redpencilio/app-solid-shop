alias Acl.Accessibility.Always, as: AlwaysAccessible
alias Acl.GraphSpec.Constraint.Resource, as: ResourceConstraint
alias Acl.GraphSpec, as: GraphSpec
alias Acl.GroupSpec, as: GroupSpec
alias Acl.GroupSpec.GraphCleanup, as: GraphCleanup

defmodule Acl.UserGroups.Config do
  def user_groups do
    # These elements are walked from top to bottom.  Each of them may
    # alter the quads to which the current query applies.  Quads are
    # represented in three sections: current_source_quads,
    # removed_source_quads, new_quads.  The quads may be calculated in
    # many ways.  The usage of a GroupSpec and GraphCleanup are
    # common.
    [
      # // PUBLIC
      %GroupSpec{
        name: "public",
        useage: [:read],
        access: %AlwaysAccessible{},
        graphs: [ %GraphSpec{
                    graph: "http://mu.semte.ch/graphs/public",
                    constraint: %ResourceConstraint{
                      resource_types: [
                        "http://purl.org/goodrelations/v1#Offering",
                        "http://purl.org/goodrelations/v1#ProductOrService",
                        "http://purl.org/goodrelations/v1#BusinessEntity",
                        "http://purl.org/goodrelations/v1#PriceSpecification"
                      ]
                    } } ] },

      # // PUBLIC IMAGES
      %GroupSpec{
        name: "images",
        useage: [:read, :write],
        access: %AlwaysAccessible{},
        graphs: [ %GraphSpec{
          graph: "http://solid-shop.org/graphs/images",
          constraint: %ResourceConstraint{
            resource_types: [
              "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject"
            ]
          } } ] },

      # // CLEANUP
      #
      %GraphCleanup{
        originating_graph: "http://mu.semte.ch/application",
        useage: [:write],
        name: "clean"
      }
    ]
  end
end
